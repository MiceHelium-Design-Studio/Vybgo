import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart' show navigatorKey;
import '../screens/rides/ride_status_screen.dart' show RideStatusScreen;

/// Notification Service
/// 
/// Handles all push notification functionality using Firebase Cloud Messaging.
/// 
/// Features:
/// - Request notification permissions
/// - Handle foreground notifications
/// - Handle background notifications
/// - Handle terminated app notifications
/// - Get FCM token for device registration
/// - Navigate to appropriate screens on notification tap
/// 
/// Setup Required:
/// 1. Create Firebase project at https://console.firebase.google.com
/// 2. Add Android app (google-services.json)
/// 3. Add iOS app (GoogleService-Info.plist)
/// 4. Enable Cloud Messaging API
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh
      _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          debugPrint('[NOTIFICATION] FCM Token refreshed: $newToken');
        }
        // TODO: Send token to backend to associate with user
      });

      // Configure foreground notification presentation
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification when app is opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleNotificationTap(message);
        }
      });

      // Handle notification when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error initializing: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      // Request notification permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Permission status: ${settings.authorizationStatus}');
      }

      // Also request Android 13+ notification permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error requesting permission: $e');
      }
      return false;
    }
  }

  /// Get FCM token for this device
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] FCM Token: $_fcmToken');
      }
      // Send token to backend (will be called after user login)
      sendTokenToBackend(_fcmToken);
      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Handle foreground notifications (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] Foreground message received: ${message.messageId}');
      debugPrint('[NOTIFICATION] Title: ${message.notification?.title}');
      debugPrint('[NOTIFICATION] Body: ${message.notification?.body}');
      debugPrint('[NOTIFICATION] Data: ${message.data}');
    }

    // Show local notification when app is in foreground
    // You can customize this to show an in-app notification banner
    _showLocalNotification(message);
  }

  /// Show local notification (for foreground messages)
  void _showLocalNotification(RemoteMessage message) {
    // In a real implementation, you'd use flutter_local_notifications
    // For now, we'll just log it
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] Showing local notification: ${message.notification?.title}');
    }
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] Notification tapped: ${message.messageId}');
      debugPrint('[NOTIFICATION] Data: ${message.data}');
    }

    // Extract notification data
    final data = message.data;
    final notificationType = data['type'] as String?;

    // Navigate based on notification type
    switch (notificationType) {
      case 'ride_status_update':
        final rideId = data['rideId'] as String?;
        if (rideId != null) {
          // Navigate to ride status screen
          // This will be handled by the app's navigation system
          _navigateToRideStatus(rideId);
        }
        break;
      case 'ride_accepted':
        final rideId = data['rideId'] as String?;
        if (rideId != null) {
          _navigateToRideStatus(rideId);
        }
        break;
      case 'ride_completed':
        final rideId = data['rideId'] as String?;
        if (rideId != null) {
          _navigateToRideStatus(rideId);
        }
        break;
      default:
        if (kDebugMode) {
          debugPrint('[NOTIFICATION] Unknown notification type: $notificationType');
        }
    }
  }

  /// Navigate to ride status screen
  void _navigateToRideStatus(String rideId) {
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] Navigate to ride status: $rideId');
    }
    
    // Use global navigator key to navigate from anywhere
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => RideStatusScreen(rideId: rideId),
      ),
    );
  }

  /// Send FCM token to backend
  /// This should be called after user login
  Future<void> sendTokenToBackend(String? token, {String? apiToken}) async {
    if (token == null) return;

    try {
      // TODO: Implement API call to send token to backend
      // You'll need to add this endpoint to your backend
      // Example endpoint: POST /api/users/fcm-token
      // 
      // final apiService = ref.read(apiServiceProvider);
      // if (apiToken != null) {
      //   apiService.setToken(apiToken);
      // }
      // await apiService.post('/users/fcm-token', {'token': token});
      
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Token ready to send to backend: $token');
        debugPrint('[NOTIFICATION] Add endpoint POST /api/users/fcm-token to your backend');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error sending token to backend: $e');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIFICATION] Error unsubscribing from topic: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenSubscription?.cancel();
  }
}


/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

