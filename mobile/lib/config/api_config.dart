class ApiConfig {
  // API base URL can be overridden via --dart-define=API_BASE_URL=...
  // 
  // Default: http://10.0.2.2:3000/api (Android Emulator)
  // 
  // Why 10.0.2.2 for Android?
  // Android emulator uses a special IP address (10.0.2.2) that maps to the host
  // machine's localhost (127.0.0.1). This allows the emulator to access services
  // running on your development machine. For iOS simulator, use localhost directly.
  // 
  // To override:
  // - iOS Simulator: flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
  // - Physical Device: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}

