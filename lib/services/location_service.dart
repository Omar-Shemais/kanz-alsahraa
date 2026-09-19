/// A compatibility shell for optional geo-search layouts.
///
/// Kanz does not collect device location. Layouts that depend on nearby stores
/// observe [canUseLocation] and stay hidden, while manual map selection stays
/// available elsewhere in the app.
class LocationData {
  const LocationData({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;
}

class LocationService {
  LocationData? get locationData => null;

  bool get canUseLocation => false;

  Future<void> init() async {}

  Future<void> requestPermission() async {}

  Future<void> awaiting({Duration? timeout}) async {}
}
