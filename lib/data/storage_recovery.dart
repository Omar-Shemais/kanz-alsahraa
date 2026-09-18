import 'dart:async';
import 'package:flutter/material.dart';

/// Keep existing data intact and offer recovery instead of a blank launch.
Future<void> initializeStorageWithRecovery(
    Future<void> Function() initialize) async {
  while (true) {
    try {
      await initialize();
      return;
    } catch (_) {
      final retry = Completer<void>();
      runApp(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('تعذر فتح البيانات المحفوظة',
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 16),
                      const Text(
                          'لم نحذف بياناتك. حاول مرة أخرى، وإذا استمرت المشكلة أغلق التطبيق وافتحه مجددًا.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          if (!retry.isCompleted) retry.complete();
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await retry.future;
    }
  }
}
