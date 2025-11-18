import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

class AppTrackingService {
  /// Request tracking permission from the user
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestTrackingPermission() async {
    // Only request on iOS 14.5+
    if (!Platform.isIOS) {
      return true; // Android doesn't need ATT
    }

    try {
      // Check current tracking status
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      
      // If already determined, return the result
      if (status == TrackingStatus.authorized) {
        return true;
      } else if (status == TrackingStatus.denied || status == TrackingStatus.restricted) {
        return false;
      }

      // Request permission if not determined
      final requestStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      
      return requestStatus == TrackingStatus.authorized;
    } catch (e) {
      print('Error requesting tracking permission: $e');
      return false;
    }
  }

  /// Check if tracking is currently authorized
  static Future<bool> isTrackingAuthorized() async {
    if (!Platform.isIOS) {
      return true; // Android doesn't need ATT
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (e) {
      print('Error checking tracking status: $e');
      return false;
    }
  }

  /// Get the current tracking status
  static Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.authorized; // Android doesn't need ATT
    }

    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (e) {
      print('Error getting tracking status: $e');
      return TrackingStatus.notDetermined;
    }
  }
}
