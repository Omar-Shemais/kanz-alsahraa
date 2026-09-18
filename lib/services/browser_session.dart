/// Coordinates account boundaries without clearing cookies on page disposal.
class BrowserSession {
  BrowserSession(this.clearNativeData);
  final Future<void> Function() clearNativeData;
  final Set<Future<void> Function()> _views = {};
  bool _dirty = true;
  Future<void>? _cleaning;
  Future<void>? _opening;
  String? _account;
  int generation = 0;

  void register(Future<void> Function() clearView) => _views.add(clearView);
  void unregister(Future<void> Function() clearView) =>
      _views.remove(clearView);

  Future<void> ensureReady() {
    if (!_dirty) return Future<void>.value();
    return _cleaning ??= _clean();
  }

  Future<void> clear() {
    generation++;
    _dirty = true;
    _account = null;
    return ensureReady();
  }

  Future<void> changeAccount(String? account) async {
    if (account != _account) await clear();
    await ensureReady();
    _account = account;
  }

  Future<void> open(
      int expectedGeneration, Future<void> Function() action) async {
    await ensureReady();
    final previous = _opening;
    final operation = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      if (expectedGeneration != generation) {
        throw StateError('Account session changed');
      }
      await action();
    }();
    _opening = operation;
    try {
      await operation;
    } finally {
      if (identical(_opening, operation)) _opening = null;
    }
  }

  Future<void> _clean() async {
    try {
      final opening = _opening;
      if (opening != null) {
        try {
          await opening;
        } catch (_) {}
      }
      // Attempt every cleanup even if one fails; never unlock on failure.
      var failed = false;
      for (final cleanup in [..._views, clearNativeData]) {
        try {
          await cleanup();
        } catch (_) {
          failed = true;
        }
      }
      if (failed) throw StateError('Browser session cleanup failed');
      _dirty = false;
    } finally {
      _cleaning = null;
    }
  }
}
