import 'package:fstore/services/native_product_link_service.dart';

/// Compatibility name for template consumers. No Firebase Dynamic Links SDK
/// or page.link requests remain; links are native store HTTPS links.
@Deprecated('Use NativeProductLinkService')
class FirebaseDynamicLinkService extends NativeProductLinkService {
  FirebaseDynamicLinkService({required super.linkService});
}
