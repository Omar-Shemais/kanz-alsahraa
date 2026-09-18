import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../modules/dynamic_layout/config/app_config.dart';

class HomeConfigScope {
  const HomeConfigScope(
      {required this.site, required this.language, required this.source});
  final String site;
  final String language;
  final String source;

  String get fingerprint => sha256
      .convert(utf8.encode(jsonEncode([site, language, source])))
      .toString();
  String get storageKey => 'kanz.home.v1.$fingerprint';
}

enum HomeConfigOrigin { bundle, stored, remote }

class HomeConfigSnapshot {
  const HomeConfigSnapshot(this.config, this.origin, this.savedAt);
  final AppConfig config;
  final HomeConfigOrigin origin;
  final DateTime? savedAt;
}

/// Public layout only. Never persist authenticated/personalized Woo cache here.
/// A valid old layout remains an offline fallback; every startup checks remotely.
class HomeConfigRepository {
  HomeConfigRepository({
    required FutureOr<dynamic> Function(String key) read,
    required Future<void> Function(String key, Map<String, dynamic> value)
        write,
    DateTime Function()? now,
  })  : _read = read,
        _write = write,
        _now = now ?? DateTime.now;

  final FutureOr<dynamic> Function(String key) _read;
  final Future<void> Function(String key, Map<String, dynamic> value) _write;
  final DateTime Function() _now;
  int _generation = 0;
  int _request = 0;
  String? _scope;
  bool _disposed = false;
  Future<void> _writes = Future.value();

  void invalidate() {
    _generation++;
    _request++;
    _scope = null;
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }

  bool _current(HomeConfigScope scope, int generation, int request) =>
      !_disposed &&
      _scope == scope.fingerprint &&
      _generation == generation &&
      _request == request;

  Future<HomeConfigSnapshot?> loadBaseline(HomeConfigScope scope,
      {required Future<AppConfig> Function() loadBundle}) async {
    if (_disposed) return null;
    invalidate();
    _scope = scope.fingerprint;
    final generation = _generation;
    final request = _request;
    HomeConfigSnapshot? result;
    try {
      final entry = await Future.sync(() => _read(scope.storageKey))
          .timeout(const Duration(seconds: 2));
      if (entry is Map &&
          entry['schema'] == 1 &&
          entry['scope'] == scope.fingerprint &&
          entry['payload'] is String &&
          entry['savedAt'] is int &&
          (entry['savedAt'] as int) > 0) {
        final payload = entry['payload'] as String;
        final digest = sha256.convert(utf8.encode(payload)).toString();
        if (entry['digest'] == digest) {
          final savedAt = DateTime.fromMillisecondsSinceEpoch(
              entry['savedAt'] as int,
              isUtc: true);
          if (!savedAt
              .isAfter(_now().toUtc().add(const Duration(minutes: 5)))) {
            result = HomeConfigSnapshot(AppConfig.fromJson(jsonDecode(payload)),
                HomeConfigOrigin.stored, savedAt);
          }
        }
      }
    } catch (_) {
      // Ignore only this unusable layout. Never erase settings or other scopes.
    }
    result ??=
        HomeConfigSnapshot(await loadBundle(), HomeConfigOrigin.bundle, null);
    return _current(scope, generation, request) ? result : null;
  }

  Future<HomeConfigSnapshot?> refresh(HomeConfigScope scope,
      {required Future<AppConfig> Function() loadRemote}) async {
    if (_disposed || _scope != scope.fingerprint) return null;
    final generation = _generation;
    final request = ++_request;
    try {
      final remote = await loadRemote();
      // Clone the full JSON, not toJson() which omits HorizonLayout/Setting.
      final payload = jsonEncode(remote.jsonData);
      final config = AppConfig.fromJson(jsonDecode(payload));
      if (!_current(scope, generation, request)) return null;
      final savedAt = _now().toUtc();
      final entry = <String, dynamic>{
        'schema': 1,
        'scope': scope.fingerprint,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'payload': payload,
        'digest': sha256.convert(utf8.encode(payload)).toString(),
      };
      // Serialize writes so a slow older save cannot finish over a newer save.
      final write = _writes.then((_) async {
        if (_current(scope, generation, request)) {
          try {
            await _write(scope.storageKey, entry);
          } catch (_) {
            // A storage failure must not discard a usable network response.
          }
        }
      });
      _writes = write;
      try {
        await write.timeout(const Duration(seconds: 2));
      } catch (_) {
        // Keep write ordering, but do not hold the displayed layout hostage.
      }
      return _current(scope, generation, request)
          ? HomeConfigSnapshot(config, HomeConfigOrigin.remote, savedAt)
          : null;
    } catch (_) {
      // The caller keeps its last usable layout on network/schema failure.
      return null;
    }
  }
}
