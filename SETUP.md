# VYBGO Setup Guide

Follow these steps to get the VYBGO app running locally.

## Prerequisites

- Node.js (v18 or higher)
- PostgreSQL (v12 or higher)
- Flutter SDK (v3.0 or higher)
- Git

## Step 1: Backend Setup (Quick Start with SQLite)

The fastest way to run the backend locally is using the included SQLite database:

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Run the development script (uses SQLite, no PostgreSQL needed):
```bash
# On Linux/Mac, you may need to make the script executable first:
chmod +x ./scripts/run-dev.sh

./scripts/run-dev.sh
```

You should see: `🚗 VYBGO API server running on port 3001` (port is configured in `.env.development`)

The API will be available at `http://localhost:3001`

## Step 1b: Backend Setup (PostgreSQL for Production)

For production or if you prefer PostgreSQL:

1. Create a PostgreSQL database:
```sql
CREATE DATABASE vybgo;
```

2. Note your database connection details (host, port, username, password)

3. Navigate to backend directory:
```bash
cd backend
```

4. Install dependencies:
```bash
npm install
```

5. Create `.env` file:
```bash
# Copy the example (or create manually)
# On Windows PowerShell:
Copy-Item .env.example .env

# On Linux/Mac:
cp .env.example .env
```

6. Edit `.env` with your database credentials:
```
DATABASE_URL="postgresql://username:password@localhost:5432/vybgo?schema=public"
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production-min-32-chars"
PORT=3000
```

7. Generate Prisma client:
```bash
npm run prisma:generate
```

8. Run database migrations:
```bash
npm run prisma:migrate
```

9. Start the backend server:
```bash
npm run dev
```

You should see: `🚗 VYBGO API server running on port 3000`

## Step 2: Mobile App Setup

1. Navigate to mobile directory:
```bash
cd mobile
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Update API base URL in `lib/services/api_service.dart`:

   **For Android Emulator (SQLite dev mode on port 3001):**
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3001/api';
   ```

   **For Android Emulator (PostgreSQL on port 3000):**
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3000/api';
   ```

   **For iOS Simulator (SQLite dev mode on port 3001):**
   ```dart
   static const String baseUrl = 'http://localhost:3001/api';
   ```

   **For iOS Simulator (PostgreSQL on port 3000):**
   ```dart
   static const String baseUrl = 'http://localhost:3000/api';
   ```

   **For Physical Device:**
   - Find your computer's IP address:
     - Windows: `ipconfig` (look for IPv4 Address)
     - Mac/Linux: `ifconfig` or `ip addr`
   - Update the URL (use port 3001 for SQLite dev mode, 3000 for PostgreSQL):
     ```dart
     static const String baseUrl = 'http://YOUR_IP_ADDRESS:3001/api';
     ```

4. Run the app:
```bash
flutter run
```

## Step 3: Test the App

1. Register a new account in the app
2. Login with your credentials
3. Create a ride:
   - Enter pickup and dropoff locations
   - Select a vibe (Chill, Party, Focus, or Romantic)
   - Book the ride
4. View ride status
5. Check ride history

## Troubleshooting

### Backend Issues

**Database connection error:**
- Verify PostgreSQL is running
- Check DATABASE_URL in `.env` is correct
- Ensure database `vybgo` exists

**Port already in use:**
- Change PORT in `.env` to a different port
- Update mobile app's baseUrl accordingly

### Mobile App Issues

**Cannot connect to API:**
- Ensure backend is running
- Check API base URL matches your setup (emulator vs physical device)
- For physical devices, ensure phone and computer are on same network
- Check firewall isn't blocking port 3000

**Build errors:**
- Run `flutter clean` then `flutter pub get`
- Ensure Flutter SDK is up to date: `flutter upgrade`

## Next Steps

- Add actual audio files for each vibe in the mobile app
- Customize the UI/UX
- Add more features as needed

## Development Tips

- Backend logs will show API requests and errors
- Use `npm run prisma:studio` to view database in a GUI
- Flutter hot reload works for quick UI changes
- Check browser console for API errors when testing


