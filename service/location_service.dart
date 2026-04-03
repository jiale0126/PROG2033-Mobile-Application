import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Landmark {
  final String name;
  final double latitude;
  final double longitude;

  Landmark({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final List<Landmark> _nearbyLandmarks = [
    Landmark(name: 'Campus Main Gate', latitude: 1.533161, longitude: 103.679852),
    Landmark(name: 'Library', latitude: 1.532900, longitude: 103.680100),
    Landmark(name: 'Student Centre', latitude: 1.533400, longitude: 103.679500),
    Landmark(name: 'Sports Complex', latitude: 1.532600, longitude: 103.679200),
    Landmark(name: 'North Hall', latitude: 1.533800, longitude: 103.680300),
    Landmark(name: 'Paradigm Mall', latitude: 3.093061, longitude: 101.623398),
    Landmark(name: 'Sutera Mall', latitude: 3.045237, longitude: 101.577532),
    Landmark(name: 'Sunway Pyramid', latitude: 3.073441, longitude: 101.606087),
    Landmark(name: 'Mid Valley Megamall', latitude: 3.117256, longitude: 101.686876),
    Landmark(name: '1 Utama Shopping Centre', latitude: 3.102566, longitude: 101.606046),
    Landmark(name: 'Empire Shopping Gallery', latitude: 3.047732, longitude: 101.610842),
    Landmark(name: 'The Curve', latitude: 3.073630, longitude: 101.606777),
  ];

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// STEP 1: Check and request permission
  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
  }

  /// STEP 2: Get current position
  Future<Position> getCurrentLocation() async {
    await _checkPermission();

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// STEP 3: Convert coordinates → readable address
  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      // Validate coordinates
      if (position.latitude == 0 && position.longitude == 0) {
        return "Invalid coordinates";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      // Build readable address
      return _formatAddress(place);

    } catch (e) {
      return "Address unavailable";
    }
  }

  Future<String> getLandmarkFromCoordinates(Position position) async {
    try {
      if (position.latitude == 0 && position.longitude == 0) {
        return "Unknown landmark";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown landmark";
      }

      final place = placemarks.first;
      return _formatLandmark(place);
    } catch (e) {
      return "Unknown landmark";
    }
  }

  String _formatLandmark(Placemark place) {
    return [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country,
    ]
        .where((element) => element != null && element.isNotEmpty)
        .join(", ");
  }

  /// STEP 4: Format address (clean output)
  String _formatAddress(Placemark place) {
    return [
      place.name,
      place.locality,
      place.administrativeArea,
      place.country
    ]
        .where((element) => element != null && element.isNotEmpty)
        .join(", ");
  }

  /// STEP 5: Combined method (optional helper)
  Future<Map<String, dynamic>> getFullLocationData() async {
    final position = await getCurrentLocation();

    final address = await getAddressFromCoordinates(position);

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
    };
  }

  Future<List<Map<String, dynamic>>> getNearbyLandmarks(
    Position position, {
    double maxDistance = 10000,
  }) async {
    final nearby = _nearbyLandmarks.map((landmark) {
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        landmark.latitude,
        landmark.longitude,
      );
      return {
        'name': landmark.name,
        'distance': distance,
      };
    }).where((item) {
      final distance = item['distance'] as double;
      return distance <= maxDistance;
    }).toList();

    nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return nearby;
  }
}

