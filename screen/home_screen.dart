import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '/services/location_service.dart';
import '/services/checkin_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationText = 'Fetching location...';
  String locationStatus = 'Calculating status...';
  String currentLandmark = 'Unknown landmark';
  double? currentLatitude;
  double? currentLongitude;
  double? distanceToTarget;
  List<Map<String, dynamic>> nearbyLandmarks = [];
  final MapController _mapController = MapController();

  // 1. Define the allowed check-in radius
  static const double allowedRadius = 500;

  // 2. Define a list of clickable landmarks on the map
  final List<Map<String, dynamic>> availableTargets = [
    {
      'name': 'Campus Main Gate',
      'lat': 1.533161,
      'lng': 103.679852,
    },
    {
      'name': 'Paradigm Mall',
      'lat': 1.5158,
      'lng': 103.6841,
    },
    {
      'name': 'Petron Bandar Seri Alam',
      'lat': 1.5078,
      'lng': 103.8592,
    },
  ];

  // 3. Currently selected target location (default is first: Campus Main Gate)
  late String selectedTargetName;
  late double targetLat;
  late double targetLng;

  @override
  void initState() {
    super.initState();
    // Initialize default target
    selectedTargetName = availableTargets[0]['name'];
    targetLat = availableTargets[0]['lat'];
    targetLng = availableTargets[0]['lng'];
    _getLocation();
  }

  // 4. Handle target selection from the map
  void _selectTarget(Map<String, dynamic> target) {
    setState(() {
      selectedTargetName = target['name'];
      targetLat = target['lat'];
      targetLng = target['lng'];
    });

    // Recompute distance and status for the new target
    _calculateDistanceAndStatus();

    // Optional: move camera to the tapped target location
    _mapController.move(LatLng(targetLat, targetLng), 14.0);

    // Show a message to inform the user the target has switched
    if (locationStatus == 'Outside allowed area') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Switched to $selectedTargetName, but you are too far to check-in!"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Switched to $selectedTargetName and within allowed range!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Extract distance calculation logic for reuse in location updates and target selection
  void _calculateDistanceAndStatus() {
    if (currentLatitude != null && currentLongitude != null) {
      final distance = Geolocator.distanceBetween(
        currentLatitude!,
        currentLongitude!,
        targetLat,
        targetLng,
      );
      final status = distance <= allowedRadius
          ? 'Within allowed area'
          : 'Outside allowed area';

      setState(() {
        distanceToTarget = distance;
        locationStatus = status;
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final address = await locationService.getAddressFromCoordinates(position);
      final landmarks = await locationService.getNearbyLandmarks(position);
      final landmark = await locationService.getLandmarkFromCoordinates(position);

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        nearbyLandmarks = landmarks;
        currentLandmark = landmark;
        locationText =
            "You are at $address\n(Lat: ${position.latitude}, Lng: ${position.longitude})";
      });

      // 计算距离
      _calculateDistanceAndStatus();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (currentLatitude != null && currentLongitude != null) {
          _mapController.move(
            LatLng(currentLatitude!, currentLongitude!),
            15.0,
          );
        }
      });
    } catch (e) {
      setState(() {
        locationText =
            "Error getting location. Please ensure location services are enabled.";
      });
    }
  }

  Future<void> checkIn() async {
    if (currentLatitude == null || currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text("Waiting for location..."))),
      );
      return;
    }

    // Check status; if not allowed, reject and show notification
    if (locationStatus == 'Outside allowed area') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text("Check-In Unsuccessful: You are too far from $selectedTargetName!"),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // End execution
    }

    // Success path logic
    await CheckInService.addCheckIn(
      locationText,
      landmark: currentLandmark.isNotEmpty ? currentLandmark : selectedTargetName,
      distance: distanceToTarget ?? 0.0,
      status: 'Successful',
      latitude: currentLatitude!,
      longitude: currentLongitude!,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(child: Text("Check-In Successful!")),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  void _refreshMap() {
    if (currentLatitude == null || currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available yet.')),
      );
      return;
    }

    _mapController.move(
      LatLng(currentLatitude!, currentLongitude!),
      15.0,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map refreshed to current location.')),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        minimumSize: const Size(200, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Check-In")),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'refreshMap',
            onPressed: _refreshMap,
            tooltip: 'Refresh Map',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'viewHistory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
            tooltip: 'History',
            child: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: currentLatitude == null || currentLongitude == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        currentLatitude!,
                        currentLongitude!,
                      ),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.internship_prog2033',
                      ),
                      // 5. Target area circle (moves with selected target)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(targetLat, targetLng),
                            radius: allowedRadius,
                            useRadiusInMeter: true, // Ensure radius is in meters
                            color: Colors.blue.withOpacity(0.2),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Marker for the user's current position
                          Marker(
                            point: LatLng(currentLatitude!, currentLongitude!),
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                          // 6. Generate selectable landmark markers with tap actions
                          ...availableTargets.map((target) {
                            bool isSelected = target['name'] == selectedTargetName;
                            return Marker(
                              point: LatLng(target['lat'], target['lng']),
                              width: 100,
                              height: 80,
                              child: GestureDetector(
                                onTap: () => _selectTarget(target), // Tap to select target
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      // If selected, show orange and bigger; otherwise gray and smaller
                                      color: isSelected ? Colors.orange : Colors.grey.shade700,
                                      size: isSelected ? 40 : 30,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        target['name'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.orange.shade800 : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    locationText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // UI shows the currently checked-in target
                  Text(
                    'Selected Target: $selectedTargetName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    distanceToTarget == null
                        ? 'Calculating distance...'
                        : 'Distance to target: ${_formatDistance(distanceToTarget!)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: locationStatus == 'Within allowed area'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildCustomButton(text: 'Check In', onPressed: checkIn),
                  const SizedBox(height: 16),
                  _buildCustomButton(text: 'Refresh Map', onPressed: _refreshMap),
                  const SizedBox(height: 16),
                  _buildCustomButton(
                    text: 'Reset Location',
                    onPressed: _getLocation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
