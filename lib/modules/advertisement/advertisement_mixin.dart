import 'package:flutter/material.dart';

import '../../models/index.dart' show AdvertisementConfig;
import '../../services/advertisement/advertisement_service.dart';

/// In-app advertising is intentionally disabled for Kanz Al Sahra.
/// Marketing campaigns run on external social platforms and do not require an
/// advertising SDK, consent form, or device-ad identifier inside the app.
class AdvertisementServiceImpl implements AdvertisementService {
  @override
  void initAdvertise(AdvertisementConfig advertisement) {}

  @override
  void requestConsentInfoUpdate() {}

  @override
  Widget getAdWidget() => const SizedBox();

  @override
  void handleAd(String? screenName) {}

  @override
  void dispose() {}
}
