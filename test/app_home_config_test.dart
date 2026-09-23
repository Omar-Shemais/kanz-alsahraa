import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/app_model.dart';
import 'package:fstore/modules/dynamic_layout/config/app_config.dart';
import 'package:fstore/services/home_config_repository.dart';
import 'package:fstore/services/service_config.dart';

AppConfig _layout(String marker, {bool extraTab = false}) =>
    AppConfig.fromJson({
      'Setting': {'MainColor': '#B18729'},
      'TabBar': [
        {'layout': 'home', 'icon': 'home'},
        if (extraTab) {'layout': 'category', 'icon': 'category'},
      ],
      'HorizonLayout': [
        {'layout': 'bannerImage', 'marker': marker}
      ],
    });

void main() {
  test('Kanz drawer is opt-in and keeps service links configurable', () {
    final baseline = _layout('baseline');
    expect(baseline.kanzDrawer, isNull);
    final config = AppConfig.fromJson({
      ...(baseline.jsonData as Map),
      'KanzDrawerV2': {
        'enabled': true,
        'showTracking': true,
        'showCorporate': false,
        'rootCategoryIds': [12, '34'],
      },
    });
    expect(config.kanzDrawer!.enabled, isTrue);
    expect(config.kanzDrawer!.showTracking, isTrue);
    expect(config.kanzDrawer!.showCorporate, isFalse);
    expect(config.kanzDrawer!.rootCategoryIds, ['12', '34']);
    expect(config.toJson()['KanzDrawerV2']['enabled'], isTrue);
  });

  late Map<String, dynamic> storage;
  late List<AppModel> models;
  HomeConfigRepository repository() => HomeConfigRepository(
      read: (key) => storage[key],
      write: (key, value) async {
        storage[key] = value;
      });
  AppModel model(Future<AppConfig> Function(String) remote) {
    final value = AppModel.withHomeConfig(
        source: () => 'https://store.example/config_ar.json',
        lang: 'ar',
        homeConfigs: repository(),
        loadRemote: remote,
        loadAsset: (_) async => jsonEncode(_layout('bundle').jsonData));
    value.isInit =
        true; // Avoid unrelated user preference/platform initialization.
    models.add(value);
    return value;
  }

  setUp(() {
    ServerConfig().setConfig({'type': 'woo', 'url': 'https://store.example'});
    storage = {};
    models = [];
  });
  tearDown(() {
    for (final value in models) {
      value.dispose();
    }
  });

  test(
      'startup renders baseline while remote remains pending and deduplicates refresh',
      () async {
    final remote = Completer<AppConfig>();
    var calls = 0;
    final value = model((_) {
      calls++;
      return remote.future;
    });
    final baseline = await value.loadAppConfig();
    expect(baseline!.jsonData['HorizonLayout'][0]['marker'], 'bundle');
    expect(value.isLoading, false);
    final refresh = value.applyAppCaching();
    expect(calls, 1);
    remote.complete(_layout('fresh'));
    await refresh;
    expect(value.appConfig!.jsonData['HorizonLayout'][0]['marker'], 'fresh');
    expect(value.homeConfigOrigin, HomeConfigOrigin.remote);
    expect(storage.length, 1);
  });

  test('refresh cannot invalidate a baseline that is still loading', () async {
    final asset = Completer<String>();
    final remote = Completer<AppConfig>();
    var calls = 0;
    final value = AppModel.withHomeConfig(
        lang: 'ar',
        source: () => 'https://store.example/config_ar.json',
        homeConfigs: repository(),
        loadAsset: (_) => asset.future,
        loadRemote: (_) {
          calls++;
          return remote.future;
        });
    value.isInit = true;
    models.add(value);
    final startup = value.loadAppConfig();
    await value.applyAppCaching();
    expect(calls, 0);
    asset.complete(jsonEncode(_layout('bundle').jsonData));
    expect(await startup, isNotNull);
    expect(calls, 1);
    remote.complete(_layout('fresh'));
    await value.applyAppCaching();
    expect(value.appConfig!.jsonData['HorizonLayout'][0]['marker'], 'fresh');
  });

  test(
      'banner refresh preserves active navigation; restart adopts stored new tabs',
      () async {
    final remote = Completer<AppConfig>();
    final value = model((_) => remote.future);
    await value.loadAppConfig();
    final activeTabs = value.appConfig!.tabBar;
    final refresh = value.applyAppCaching();
    remote.complete(_layout('fresh', extraTab: true));
    await refresh;
    expect(identical(value.appConfig!.tabBar, activeTabs), true);
    expect(value.appConfig!.tabBar.length, 1);
    final secondPending = Completer<AppConfig>();
    final restarted = model((_) => secondPending.future);
    await restarted.loadAppConfig();
    expect(restarted.appConfig!.tabBar.length, 2);
    expect(restarted.homeConfigOrigin, HomeConfigOrigin.stored);
    secondPending.completeError(StateError('Offline'));
    await restarted.applyAppCaching();
    expect(restarted.appConfig!.tabBar.length, 2);
  });

  test('remote failure keeps usable baseline without leaking technical details',
      () async {
    final value = model((_) async => throw StateError('PRIVATE_UPSTREAM'));
    await value.loadAppConfig();
    await value.applyAppCaching();
    expect(value.appConfig!.jsonData['HorizonLayout'][0]['marker'], 'bundle');
    expect(value.homeConfigOrigin, HomeConfigOrigin.bundle);
    expect(storage, isEmpty);
  });

  test('explicit layout replacement invalidates pending old cloud response',
      () async {
    final remote = Completer<AppConfig>();
    final value = model((_) => remote.future);
    await value.loadAppConfig();
    final oldRefresh = value.applyAppCaching();
    // Prevent unrelated legacy Woo hook when providing an explicit layout.
    ServerConfig().isBuilder = true;
    try {
      await value.loadAppConfig(
          config: Map<String, dynamic>.from(_layout('explicit').jsonData));
      remote.complete(_layout('stale'));
      await oldRefresh;
      expect(
          value.appConfig!.jsonData['HorizonLayout'][0]['marker'], 'explicit');
      expect(storage, isEmpty);
    } finally {
      ServerConfig().isBuilder = false;
    }
  });

  test('disposed model ignores remote result without later notifications',
      () async {
    final remote = Completer<AppConfig>();
    final value = model((_) => remote.future);
    await value.loadAppConfig();
    final refresh = value.applyAppCaching();
    value.dispose();
    models.remove(value);
    remote.complete(_layout('late'));
    await refresh;
    expect(storage, isEmpty);
  });
}
