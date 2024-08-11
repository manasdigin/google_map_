import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  GoogleMapController? mapController;
  LatLng? _currentPosition;
  late MarkerId _currentMarkerId;

  var geolocator = Geolocator();

  @override
  void initState() {
    super.initState();
    _currentMarkerId = const MarkerId('current_location');

    getLocation();
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double long = position.longitude;

    LatLng location = LatLng(lat, long);

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
              initialCameraPosition: CameraPosition(
                target: _currentPosition!, // Default position
                zoom: 16.0,
              ),
              markers: markers.values.toSet(),
            ),
    );
  }

  void _onMapTapped(LatLng position) async {
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
}
