# VYBGO Mobile App

Flutter mobile app for the VYBGO ride-hailing service.

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Add audio assets:
   - Create `assets/audio/` directory in the project root
   - Add MP3 files: `chill_1.mp3`, `chill_2.mp3`, `party_1.mp3`, `focus_1.mp3`, `romantic_1.mp3`
   - The app will automatically load these assets

3. Configure the API base URL:
   - The default is set for Android emulator: `http://10.0.2.2:3000/api`
   - To override, use: `flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api`
   - For iOS simulator: `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api`
   - For physical device: `flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3000/api`

3. Run the app:
```bash
flutter run
```

## Features

- User registration and login
- Vibe selection (Chill, Party, Focus, Romantic)
- Create rides with pickup and dropoff locations
- View ride status
- View ride history
- Play music based on selected vibe (uses local audio assets)

## Project Structure

- `lib/main.dart` - App entry point
- `lib/services/` - API and business logic services
- `lib/screens/` - UI screens
  - `auth/` - Login and registration
  - `home/` - Home screen
  - `rides/` - Ride-related screens


