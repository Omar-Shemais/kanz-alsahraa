import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/modules/dynamic_layout/config/app_config.dart';
import 'package:fstore/services/home_config_repository.dart';
import 'package:fstore/services/home_config_sources.dart';
import 'package:hive_flutter/hive_flutter.dart';

AppConfig _config(String marker) => AppConfig.fromJson({
      'Setting': {'MainColor': '#B18729'},
      'TabBar': [
        {'layout': 'home', 'icon': 'home'}
      ],
      'HorizonLayout': [
        {'layout': 'bannerImage', 'marker': marker}
      ],
    });

String _marker(HomeConfigSnapshot? snapshot) =>
    snapshot!.config.jsonData['HorizonLayout'][0]['marker'] as String;

void main() {
  const scope = HomeConfigScope(
      site: 'https://store.example',
      language: 'ar',
      source: 'https://store.example/config.json');
  final now = DateTime.utc(2026, 9, 17, 12);
  late Map<String, dynamic> storage;
  late HomeConfigRepository repository;
  HomeConfigRepository create() => HomeConfigRepository(
      read: (key) => storage[key],
      write: (key, value) async {
        storage[key] = value;
      },
      now: () => now);
  Future<HomeConfigSnapshot?> baseline([HomeConfigScope target = scope]) =>
      repository.loadBaseline(target,
          loadBundle: () async => _config('bundle'));
  Future<HomeConfigSnapshot?> refresh(String marker) =>
      repository.refresh(scope, loadRemote: () async => _config(marker));

  setUp(() {
    storage = {};
    repository = create();
  });

  test('first startup returns bundled layout without network', () async {
    final result = await baseline();
    expect(result!.origin, HomeConfigOrigin.bundle);
    expect(_marker(result), 'bundle');
    expect(storage, isEmpty);
  });

  test('remote full JSON survives restart without requiring bundle', () async {
    await baseline();
    expect((await refresh('fresh'))!.origin, HomeConfigOrigin.remote);
    repository = create();
    final result = await repository.loadBaseline(scope,
        loadBundle: () async => throw StateError('Bundle must not be needed'));
    expect(result!.origin, HomeConfigOrigin.stored);
    expect(result.savedAt, now);
    expect(_marker(result), 'fresh');
    expect(result.config.settings.mainColor, '#B18729');
    expect(result.config.tabBar.single.layout, 'home');
    expect(jsonEncode(storage), isNot(contains('store.example')));
  });

  for (final target in [
    const HomeConfigScope(
        site: 'https://store.example',
        language: 'en',
        source: 'https://store.example/config.json'),
    const HomeConfigScope(
        site: 'https://other.example',
        language: 'ar',
        source: 'https://store.example/config.json'),
    const HomeConfigScope(
        site: 'https://store.example',
        language: 'ar',
        source: 'https://store.example/another.json'),
  ]) {
    test(
        'scope does not reuse another site/language/source: ${target.fingerprint}',
        () async {
      await baseline();
      await refresh('private-to-scope');
      expect(_marker(await baseline(target)), 'bundle');
      expect(storage.length, 1);
    });
  }

  for (final field in ['schema', 'scope', 'digest', 'savedAt', 'payload']) {
    test('corrupt $field falls back without deleting unrelated settings',
        () async {
      await baseline();
      await refresh('fresh');
      storage['other-setting'] = 'keep';
      final entry = storage[scope.storageKey] as Map;
      entry[field] = field == 'schema' ? 99 : 'invalid';
      expect(_marker(await baseline()), 'bundle');
      expect(storage['other-setting'], 'keep');
      expect(storage.containsKey(scope.storageKey), true);
    });
  }

  test('valid digest cannot authorize an invalid configuration contract',
      () async {
    await baseline();
    await refresh('fresh');
    final entry = storage[scope.storageKey] as Map;
    entry['payload'] = '{}';
    entry['digest'] = sha256.convert(utf8.encode('{}')).toString();
    expect(_marker(await baseline()), 'bundle');
  });

  test('future-dated snapshot is ignored', () async {
    await baseline();
    await refresh('fresh');
    (storage[scope.storageKey] as Map)['savedAt'] =
        now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    expect(_marker(await baseline()), 'bundle');
  });

  test('old valid snapshot remains usable offline but preserves its age',
      () async {
    await baseline();
    await refresh('fresh');
    final oldDate = now.subtract(const Duration(days: 30));
    (storage[scope.storageKey] as Map)['savedAt'] =
        oldDate.millisecondsSinceEpoch;
    final result = await baseline();
    expect(_marker(result), 'fresh');
    expect(result!.savedAt, oldDate);
    expect(result.origin, HomeConfigOrigin.stored);
  });

  test('read failure returns valid bundle without attempting erase', () async {
    repository = HomeConfigRepository(
      read: (_) => throw StateError('I/O'),
      write: (_, __) async => fail('Unexpected write'),
    );
    expect(_marker(await baseline()), 'bundle');
  });

  test('network failure does not overwrite last good snapshot', () async {
    await baseline();
    await refresh('fresh');
    final before = jsonEncode(storage);
    final result = await repository.refresh(scope,
        loadRemote: () async => throw StateError('Network failure'));
    expect(result, null);
    expect(jsonEncode(storage), before);
    expect(_marker(await baseline()), 'fresh');
  });

  test('malformed remote model cannot overwrite last good snapshot', () async {
    await baseline();
    await refresh('fresh');
    final bad = _config('bad')..jsonData = {};
    expect(await repository.refresh(scope, loadRemote: () async => bad), null);
    expect(_marker(await baseline()), 'fresh');
  });

  test('failed disk save does not discard usable network layout', () async {
    repository = HomeConfigRepository(
        read: (_) => null,
        write: (_, __) async => throw StateError('Disk unavailable'));
    await baseline();
    expect(_marker(await refresh('fresh')), 'fresh');
  });

  test('newer network response wins over slower older response', () async {
    await baseline();
    final older = Completer<AppConfig>();
    final oldResult = repository.refresh(scope, loadRemote: () => older.future);
    expect(_marker(await refresh('newer')), 'newer');
    older.complete(_config('older'));
    expect(await oldResult, null);
    expect(_marker(await baseline()), 'newer');
  });

  test('language switch invalidates pending previous-locale refresh', () async {
    await baseline();
    final older = Completer<AppConfig>();
    final oldResult = repository.refresh(scope, loadRemote: () => older.future);
    const en = HomeConfigScope(
        site: 'https://store.example',
        language: 'en',
        source: 'https://store.example/config.json');
    await baseline(en);
    older.complete(_config('ar'));
    expect(await oldResult, null);
    expect(storage, isEmpty);
  });

  test('dispose prevents delayed publishing and saving', () async {
    await baseline();
    final older = Completer<AppConfig>();
    final oldResult = repository.refresh(scope, loadRemote: () => older.future);
    repository.dispose();
    older.complete(_config('late'));
    expect(await oldResult, null);
    expect(await baseline(), null);
    expect(storage, isEmpty);
  });

  test('serialized disk writes leave the newest snapshot after older slow save',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var writes = 0;
    repository = HomeConfigRepository(
        read: (key) => storage[key],
        write: (key, value) async {
          if (++writes == 1) {
            started.complete();
            await release.future;
          }
          storage[key] = value;
        },
        now: () => now);
    await baseline();
    final older = refresh('older');
    await started.future;
    final newer = refresh('newer');
    release.complete();
    expect(await older, null);
    expect(_marker(await newer), 'newer');
    expect(_marker(await baseline()), 'newer');
  });

  test('slow cache read cannot publish over new scope', () async {
    final pending = Completer<dynamic>();
    var reads = 0;
    repository = HomeConfigRepository(
        read: (_) => ++reads == 1 ? pending.future : null,
        write: (_, __) async {});
    final older = baseline();
    const en = HomeConfigScope(
        site: 'https://store.example',
        language: 'en',
        source: 'https://store.example/config.json');
    expect(_marker(await baseline(en)), 'bundle');
    pending.complete(null);
    expect(await older, null);
  });

  test('HTTPS locale URL preserves query and includes folder', () {
    expect(
        homeRemoteUrls(
            source: 'https://cdn.example/config.json?v=3',
            language: 'ar',
            folder: 'store'),
        [
          'https://cdn.example/store/config_ar.json?v=3',
          'https://cdn.example/config.json?v=3',
        ]);
  });
  test('exact locale source is not fetched twice', () {
    expect(
        homeRemoteUrls(
            source: 'https://cdn.example/config_ar.json', language: 'ar'),
        ['https://cdn.example/config_ar.json']);
  });
  test('unsafe remote source has no URL candidates', () {
    for (final source in [
      'http://cdn.example/config.json',
      'https://user@cdn.example/config.json',
      'lib/config/config_ar.json'
    ]) {
      expect(homeRemoteUrls(source: source, language: 'ar'), isEmpty);
    }
  });
  test('remote folder fallback cannot accidentally load another site bundle',
      () {
    expect(
        homeBundlePaths(
            source: 'https://cdn.example/config.json',
            language: 'ar',
            folder: 'store',
            fallbackLanguage: 'en'),
        [
          'lib/config/store/config_ar.json',
          'lib/config/store/config_en.json',
        ]);
  });
  test('invalid/missing language bundle falls back to packaged default',
      () async {
    final paths = <String>[];
    final config = await loadBundledHomeConfig(
        ['missing', 'invalid', 'default'], (path) async {
      paths.add(path);
      if (path == 'missing') throw StateError('Missing');
      return path == 'invalid' ? '{}' : jsonEncode(_config('bundle').jsonData);
    });
    expect(paths, ['missing', 'invalid', 'default']);
    expect(config.jsonData['HorizonLayout'][0]['marker'], 'bundle');
  });

  test('snapshot survives closing and reopening actual Hive disk storage',
      () async {
    final temp = await Directory.systemTemp.createTemp('kanz-home-hive-test-');
    try {
      Hive.init(temp.path);
      var box = await Hive.openBox('kanz-home-test');
      repository = HomeConfigRepository(
          read: (key) => box.get(key),
          write: (key, value) => box.put(key, value),
          now: () => now);
      await baseline();
      await refresh('disk-persisted');
      await box.flush();
      await box.close();
      box = await Hive.openBox('kanz-home-test');
      final result = await baseline();
      expect(result!.origin, HomeConfigOrigin.stored);
      expect(_marker(result), 'disk-persisted');
    } finally {
      await Hive.close();
      await temp.delete(recursive: true);
    }
  });
}
