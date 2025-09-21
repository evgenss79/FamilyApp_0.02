/// Provides geolocation utilities.  The stub implementation always
/// returns a fixed location.  Expand as needed for actual location
/// retrieval.
class GeoService {
  Future<String> getCurrentLocation() async {
    // Return a placeholder location; in a real app this would use
    // geolocator or platform-specific APIs.
    return 'Unknown';
  }
}