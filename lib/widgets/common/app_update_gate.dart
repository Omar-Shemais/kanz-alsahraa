import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_update_policy.dart';

class AppUpdateGate extends StatefulWidget {
  final dynamic config;
  final Widget child;
  final Future<int> Function()? readBuild;
  final TargetPlatform? platform;

  const AppUpdateGate(
      {super.key,
      required this.config,
      required this.child,
      this.readBuild,
      this.platform});

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  AppUpdatePolicy? _policy;
  bool _policyCaptured = false;
  int? _build;
  bool _loading = false;
  bool _failed = false;
  bool _opening = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Snapshot the startup policy. Never interrupt an ongoing payment because
    // a home-layout refresh arrives later in the same session.
    _captureStartupPolicy();
  }

  @override
  void didUpdateWidget(covariant AppUpdateGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The splash can construct MaterialApp before its first config arrives.
    if (!_policyCaptured) _captureStartupPolicy();
  }

  void _captureStartupPolicy() {
    if (_policyCaptured || widget.config is! Map) return;
    _policyCaptured = true;
    _policy = kIsWeb
        ? null
        : AppUpdatePolicy.fromConfig(
            widget.config, widget.platform ?? defaultTargetPlatform);
    if (_policy != null) _readBuild();
  }

  Future<void> _readBuild() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final read = widget.readBuild ??
          () async {
            final info = await PackageInfo.fromPlatform();
            final number = int.tryParse(info.buildNumber);
            if (number == null || number < 1) throw const FormatException();
            return number;
          };
      final build = await read().timeout(const Duration(seconds: 5));
      if (build < 1) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _build = build;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _message = null;
    });
    try {
      final opened = await launchUrl(_policy!.storeUrl,
              mode: LaunchMode.externalApplication)
          .timeout(const Duration(seconds: 5));
      if (!opened && mounted) {
        setState(() {
          _message = 'تعذر فتح المتجر. حاول مرة أخرى.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'تعذر فتح المتجر. حاول مرة أخرى.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _policy != null &&
        (_loading ||
            _failed ||
            _build == null ||
            _policy!.requiresUpdate(_build!));
    return Stack(fit: StackFit.expand, children: [
      // Keep the navigator alive so background callbacks/navigation do not
      // lose their state. Block input and semantics while an update is needed.
      Offstage(
          offstage: blocked,
          child: TickerMode(enabled: !blocked, child: widget.child)),
      if (blocked)
        Positioned.fill(
            child: PopScope(
                canPop: false,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.system_update, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                    _failed
                                        ? 'تعذر قراءة إصدار التطبيق'
                                        : 'يرجى تحديث التطبيق',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 12),
                                const Text(
                                    'استخدم أحدث إصدار من كنز الصحراء للمتابعة.',
                                    textAlign: TextAlign.center),
                                if (_loading)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator()),
                                if (!_loading)
                                  FilledButton(
                                      onPressed: _opening ? null : _openStore,
                                      child: const Text('فتح متجر التطبيقات')),
                                if (_failed)
                                  TextButton(
                                      onPressed: _readBuild,
                                      child: const Text('إعادة المحاولة')),
                                if (_message != null)
                                  Text(_message!, textAlign: TextAlign.center),
                              ],
                            )),
                      )),
                ))),
    ]);
  }
}
