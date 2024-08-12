import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class GeofencingService {
  final NotificationService _notificationService = NotificationService();

  // Define your shop's location and radius
  final double shopLatitude = 37.7749;
  final double shopLongitude = -122.4194;
  final double geofenceRadius = 100.0; // Radius in meters

  Future<void> init() async {
    await _notificationService.init();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high))
        .listen((Position position) {
      _checkGeofence(position.latitude, position.longitude);
    });
  }

  void _checkGeofence(double latitude, double longitude) {
    final double distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      shopLatitude,
      shopLongitude,
    );

    if (distance <= geofenceRadius) {
      _notificationService.showNotification(
        'Welcome!',
        'Hi, you are welcome to the YYY shop!',
      );
    } else {
      // If you want to notify when the user leaves the area, you can implement that here.
    }
  }
}
