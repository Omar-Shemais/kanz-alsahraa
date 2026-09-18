import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'boxes.dart';

class SecureStorage {
  final FlutterSecureStorage _secureStorage;
  final bool _disablePersistence;
  final Future<void> Function(Duration) _wait;
  Map<String, String> _storage = {};
  Future<void>? _initializing;
  bool _isInitialized = false;

  static final SecureStorage _instance = SecureStorage.withStorage(
    const FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: false)),
    disablePersistence: kDisableWebCookies,
  );

  factory SecureStorage() => _instance;

  SecureStorage.withStorage(
    this._secureStorage, {
    bool disablePersistence = false,
    Future<void> Function(Duration)? wait,
  })  : _disablePersistence = disablePersistence,
        _wait = wait ?? Future<void>.delayed;

  Future<void> init() {
    if (_isInitialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!_disablePersistence) {
        for (var attempt = 0; attempt < 3; attempt++) {
          try {
            _storage = await _secureStorage.readAll();
            break;
          } catch (_) {
            if (attempt == 2) rethrow;
            await _wait(Duration(milliseconds: 300 * (1 << attempt)));
          }
        }
      }
      _isInitialized = true;
    } finally {
      _initializing = null;
    }
  }

  String get(String key) {
    if (!_isInitialized) throw StateError('Secure storage is not initialized');
    return _storage[key] ?? '';
  }

  Future<void> set(String key, String value) async {
    if (!_isInitialized) throw StateError('Secure storage is not initialized');
    if (!_disablePersistence) {
      await _secureStorage.write(key: key, value: value);
    }
    _storage[key] = value;
  }
}
