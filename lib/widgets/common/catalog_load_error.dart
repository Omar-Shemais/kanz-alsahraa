import 'package:flutter/material.dart';

class CatalogLoadError extends StatelessWidget {
  const CatalogLoadError(
      {super.key, required this.onRetry, this.loading = false});
  final VoidCallback onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final arabic = Directionality.of(context) == TextDirection.rtl;
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 36),
        const SizedBox(height: 16),
        Text(
            arabic
                ? 'تعذر تحميل بيانات المتجر. تحقق من الاتصال وأعد المحاولة.'
                : 'Unable to load store data. Check your connection and try again.',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: loading ? null : onRetry,
            child: Text(arabic ? 'إعادة المحاولة' : 'Try again')),
      ]),
    ));
  }
}
