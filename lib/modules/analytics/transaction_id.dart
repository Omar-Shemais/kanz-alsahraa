/// Woo WebView returns an order number rather than a full Order entity.
/// Do not invent a transaction reference when neither identifier exists.
String? analyticsTransactionId(String? id, String? number) {
  for (final candidate in [id, number]) {
    final reference = candidate?.trim();
    if (reference != null &&
        reference.isNotEmpty &&
        reference.length <= 128 &&
        !RegExp(r'[\x00-\x1F\x7F]').hasMatch(reference)) {
      return reference;
    }
  }
  return null;
}
