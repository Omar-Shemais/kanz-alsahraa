import 'package:flutter/foundation.dart';

/// Public layout policy, not an authentication/security boundary.
class AppUpdatePolicy {
  final int minimumBuild;
  final Uri storeUrl;

  const AppUpdatePolicy(this.minimumBuild, this.storeUrl);

  bool requiresUpdate(int build) => build < minimumBuild;

  static AppUpdatePolicy? fromConfig(dynamic config, TargetPlatform platform) {
    if (config is! Map || config['KanzControl'] is! Map) return null;
    final updates = config['KanzControl']['updates'];
    if (updates is! Map) return null;
    final key = switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (key == null) return null;
    final setting = updates[key];
    if (setting is! Map || setting['enabled'] != true) return null;
    final minimum = setting['minimumBuild'];
    if (minimum is! int || minimum < 1 || minimum > 2147483647) return null;
    return AppUpdatePolicy(
      minimum,
      Uri.parse(platform == TargetPlatform.android
          ? 'https://play.google.com/store/apps/details?id=com.khtwah.kanzalsahra'
          : 'https://apps.apple.com/app/id1564098406'),
    );
  }
}
