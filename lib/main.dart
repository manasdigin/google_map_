import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_flutter/service/geofencing_service.dart';
import 'package:google_map_flutter/service/notification_service.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:google_maps_flutter/google_maps_flutter.dart';

//geolocator
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green[700],
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GeofencingService _geofencingService = GeofencingService();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  GoogleMapController? mapController;
  LatLng? _currentPosition;
  late MarkerId _currentMarkerId;
  final List<LatLng> geofencePoints = [
    const LatLng(8.1938305, 77.3093004),
    const LatLng(8.1940305, 77.3093004), // Increased latitude
    const LatLng(8.1940305, 77.3103004), // Increased longitude
    const LatLng(8.1938305, 77.3103004), // Increased longitude
    const LatLng(8.1938305, 77.3093004), // Close the polygon
  ];
  Set<Polygon> polygons = {};
  var geolocator = Geolocator();

  @override
  void initState() {
    super.initState();
    _currentMarkerId = const MarkerId('current_location');
    _geofencingService.init();

    getLocation();
    // Future.delayed(Duration.zero, () {
    //   _createGeofence();
    // });
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double long = position.longitude;
    List<LatLng> polygonPoints = [];

    LatLng location = LatLng(lat, long);
    print("🤕🤕$lat, $long");

    setState(() {
      _currentPosition = location;
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16.0),
    );

    final updatedMarker = Marker(
      markerId: _currentMarkerId,
      position: location,
      infoWindow: const InfoWindow(
        title: 'Current Location',
      ),
    );

    setState(() {
      markers[_currentMarkerId] = updatedMarker;
    });
  }

  static List<LatLng> geofenceBoundary = [
    const LatLng(8.1938172, 77.3092479),
    const LatLng(8.1938172, 77.3092479),
  ];
  Polygon polygon = Polygon(
    polygonId: const PolygonId('polygon'),
    points: geofenceBoundary,
    strokeColor: Colors.black,
    fillColor: Colors.red.withOpacity(0.5),
  );

  // void _createGeofence() {
  //   // if (geofencePoints.length < 3) {
  //   //   ScaffoldMessenger.of(context).showSnackBar(
  //   //     const SnackBar(content: Text('Add at least 3 points for the geofence')),
  //   //   );
  //   //   return;
  //   // }

  //   setState(() {
  //     polygons.add(Polygon(
  //       polygonId: const PolygonId('geofence'),
  //       points: geofencePoints,
  //       fillColor: Colors.red.withOpacity(0.3),
  //       strokeColor: Colors.red,
  //       strokeWidth: 2,
  //     ));
  //   });

  //   // Calculate area of the geofence
  //   List<mt.LatLng> toolkitPoints =
  //       geofencePoints.map((p) => mt.LatLng(p.latitude, p.longitude)).toList();
  //   double area = mt.SphericalUtil.computeArea(toolkitPoints) / 1000000;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //         content: Text(
  //             'Geofence created. Area: ${area.toStringAsFixed(2)} sq meters')),
  //   );
  // }

  bool isPointInGeofence(LatLng point) {
    // if (geofencePoints.length < 3) return false;

    List<mt.LatLng> toolkitPoints =
        geofencePoints.map((p) => mt.LatLng(p.latitude, p.longitude)).toList();
    mt.LatLng toolkitPoint = mt.LatLng(point.latitude, point.longitude);

    return mt.PolygonUtil.containsLocation(toolkitPoint, toolkitPoints, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Office Locations'),
        elevation: 2,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped,
              //          onCameraIdle: () {
              //   // Check if the visible area intersects with the geofence boundary
              //   LatLngBounds visibleArea = mapController?.getVisibleRegion();
              //   if (isVisibleWithinGeofence(visibleArea)) {
              //     // User is within the geofence
              //   } else {
              //     // User is outside the geofence
              //   }
              // },
              initialCameraPosition: CameraPosition(
                target: _currentPosition!, // Default position
                zoom: 16.0,
              ),
              circles: <Circle>{
                Circle(
                    circleId: const CircleId("C1"),
                    center: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    consumeTapEvents: true,
                    fillColor: Colors.red.shade200,
                    onTap: () {
                      _onMapTapped(LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude));
                    },
                    radius: 200,
                    strokeColor: Colors.amber,
                    strokeWidth: 1,
                    visible: true,
                    zIndex: 15)
              },
              markers: markers.values.toSet(),
              polygons: polygons,
            ),
    );
  }

  void _onMapTapped(LatLng position) async {
    // _addGeofencePoint(position);
    if (_isInsideGeofence(position)) {
      NotificationService()
          .showNotification('You are inside the geofence', 'Happy Purchase!');
    } else {
      NotificationService()
          .showNotification('You are outside the geofence', 'Sorry!');
    }
    Circle(
      circleId: const CircleId("1"),
      center: position,
      fillColor: Colors.amber.shade100,

      radius:
          500, // Adjust this value as needed for your geofencing requirements
      strokeColor: Colors.brown,
      strokeWidth: 2,
      visible: true,
      zIndex: 12,
      consumeTapEvents: true,
    );

    print(position);
    try {
      List<Placemark>? placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16.0),
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Name: ${place.name ?? "N/A"}'),
                  Text('Street: ${place.street ?? "N/A"}'),
                  Text('Locality: ${place.locality ?? "N/A"}'),
                  Text('Sublocality: ${place.subLocality ?? "N/A"}'),
                  Text(
                      'Administrative Area: ${place.administrativeArea ?? "N/A"}'),
                  Text('Postal Code: ${place.postalCode ?? "N/A"}'),
                  Text('Country: ${place.country ?? "N/A"}'),
                ],
              ),
            );
          },
        );

        final updatedMarker = Marker(
          markerId: _currentMarkerId,
          position: position,
          infoWindow: InfoWindow(
            title: place.name ?? 'No Name',
            snippet: place.locality ?? 'No Address',
          ),
        );

        setState(() {
          markers[_currentMarkerId] = updatedMarker;
        });
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location details')),
      );
    }
  }

  void _addGeofencePoint(LatLng point) {
    setState(() {
      geofencePoints.add(point);
      markers[MarkerId('geofence_${geofencePoints.length}')] = Marker(
        markerId: MarkerId('geofence_${geofencePoints.length}'),
        position: point,
      );
    });
  }

  bool _isInsideGeofence(LatLng position) {
    final circleCenter =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    const radiusInMeters = 200.0; // Same as circle radius
    final distance = _calculateDistance(circleCenter, position);
    return distance <= radiusInMeters;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // _createGeofence();
  }
}
