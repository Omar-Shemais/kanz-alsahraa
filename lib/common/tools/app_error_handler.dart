import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/app_telemetry.dart';
import '../constants.dart';

/// Safe fallback UI with optional forwarding to initialized app telemetry.
class AppErrorHandler {
  AppErrorHandler._();

  static void init() {
    // Raw exceptions and URLs can contain credentials and customer data.
    FlutterError.onError = (details) {
      AppTelemetry.report(details.exception, details.stack ?? StackTrace.empty,
          fatal: false);
      printLog('[AppErrorHandler] Framework error.');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppTelemetry.report(error, stack, fatal: true);
      printLog('[AppErrorHandler] Unhandled platform error.');
      return true;
    };
    ErrorWidget.builder = (details) => KanzLuxuryErrorWidget(details: details);
  }
}

class KanzLuxuryErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const KanzLuxuryErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x59B18729)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFB18729), size: 32),
              const SizedBox(height: 12),
              Text(
                'تعذر عرض هذا القسم',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'حاول فتح الصفحة مرة أخرى.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
