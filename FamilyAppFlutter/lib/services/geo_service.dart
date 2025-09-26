import 'package:geolocator/geolocator.dart';

/// Android geolocation helper that requests permissions and retrieves the
/// current coordinates using the `geolocator` plugin.
class GeoService {
  const GeoService();

  /// Requests runtime permissions if needed and returns whether access was
  /// granted. When permissions are denied forever we surface `false` so the
  /// caller can route the user to system settings.
  Future<bool> ensurePermissions() async {
    // ANDROID-ONLY FIX: guard against disabled Android location services.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Returns the device location if permissions are granted, otherwise null.
  Future<Position?> getCurrentPosition() async {
    final bool granted = await ensurePermissions();
    if (!granted) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}