import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/map/map_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Flag indicating whether Firebase initialized successfully. Used to
// skip notification setup when Firebase is not configured (e.g. local dev).
bool firebaseAvailable = false;
// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function is called when app is in background or terminated
  // Handle background notification processing here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    firebaseAvailable = true;
  } catch (e) {
    // Firebase not configured yet - app will still work without notifications
    debugPrint('[MAIN] Firebase initialization error: $e');
    debugPrint('[MAIN] App will continue without push notifications');
  }
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bkltwqmkajwhatnyzogs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrbHR3cW1rYWp3aGF0bnl6b2dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NzAwMTksImV4cCI6MjA3OTM0NjAxOX0.MeYvCJJ9PP4GyUSjDMD0jNKbr1R2gjMiPz8dXoMtVII',
  );
  
  runApp(const ProviderScope(child: VybgoApp()));
}

class VybgoApp extends StatelessWidget {
  const VybgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VYBGO',
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle reset password route with token parameter
        if (settings.name?.startsWith('/reset-password/') ?? false) {
          final token = settings.name!.substring('/reset-password/'.length);
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: token),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    // Skip initializing notifications when Firebase isn't available. This
    // prevents Firebase errors from surfacing in the UI when you are using
    // Supabase-only auth or running local dev without Firebase config.
    if (!firebaseAvailable) {
      if (kDebugMode) debugPrint('[AUTH] Skipping notification init (Firebase not available)');
      return;
    }

    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    } catch (e) {
      debugPrint('[AUTH] Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getStoredToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          // Set token in auth service
          ref.read(authServiceProvider).setToken(token);
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

