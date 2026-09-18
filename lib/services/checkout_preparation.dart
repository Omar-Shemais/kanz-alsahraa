import 'dart:async';

/// Applies only before opening payment, not while a customer is paying.
Future<T> prepareCheckout<T>(Future<T> Function() request,
    {Duration timeout = const Duration(seconds: 10)}) async {
  return await request().timeout(timeout);
}
