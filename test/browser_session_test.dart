import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/browser_session.dart';

void main() {
  test('initial cleanup is awaited once and unregister does not clear payment',
      () async {
    final release = Completer<void>();
    var native = 0;
    var views = 0;
    final session = BrowserSession(() async {
      native++;
      await release.future;
    });
    Future<void> view() async {
      views++;
    }

    session.register(view);
    var ready = false;
    final first = session.ensureReady().then((_) {
      ready = true;
    });
    final second = session.ensureReady();
    await Future<void>.delayed(Duration.zero);
    expect(ready, false);
    release.complete();
    await Future.wait([first, second]);
    expect(native, 1);
    expect(views, 1);
    session.unregister(view);
    await session.ensureReady();
    expect(native, 1);
    await session.clear();
    expect(native, 2);
    expect(views, 1);
  });
  test('failure tries remaining cleanup and blocks page opening until recovery',
      () async {
    var fail = true;
    var native = 0;
    var opened = false;
    final session = BrowserSession(() async {
      native++;
    });
    session.register(() async {
      if (fail) throw StateError('failed');
    });
    await expectLater(
        session.open(0, () async {
          opened = true;
        }),
        throwsStateError);
    expect(opened, false);
    expect(native, 1);
    fail = false;
    await session.open(0, () async {
      opened = true;
    });
    expect(opened, true);
    expect(native, 2);
  });
  test('same account retains checkout; account change invalidates old pages',
      () async {
    var native = 0;
    final session = BrowserSession(() async {
      native++;
    });
    await session.changeAccount('first');
    final old = session.generation;
    await session.changeAccount('first');
    expect(native, 1);
    await session.changeAccount('second');
    expect(native, 2);
    var opened = false;
    await expectLater(
        session.open(old, () async {
          opened = true;
        }),
        throwsStateError);
    expect(opened, false);
    await session.open(session.generation, () async {
      opened = true;
    });
    expect(opened, true);
  });
  test('logout waits for pending cookie installation before native purge',
      () async {
    final events = <String>[];
    final session = BrowserSession(() async {
      events.add('purge');
    });
    await session.ensureReady();
    events.clear();
    final release = Completer<void>();
    final started = Completer<void>();
    final opening = session.open(0, () async {
      started.complete();
      await release.future;
      events.add('cookie');
    });
    await started.future;
    final logout = session.clear();
    release.complete();
    await Future.wait([opening, logout]);
    expect(events, ['cookie', 'purge']);
  });
}
