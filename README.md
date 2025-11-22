# VYBGO - Ride-Hailing App with Vibes

VYBGO is a mobile ride-hailing app where riders choose a "vibe" (Chill, Party, Focus, Romantic) and book a ride. The app plays music locally based on the selected vibe.

## Project Structure

```
.
├── backend/          # Node.js + TypeScript + Express + PostgreSQL + Prisma
└── mobile/          # Flutter app with Riverpod
```

## MVP Features (Phase 1)

- ✅ User registration and login (email + password, JWT)
- ✅ Vibe selection (Chill, Party, Focus, Romantic)
- ✅ Create rides (pickup, dropoff, vibe)
- ✅ View ride status
- ✅ View ride history
- ✅ Play music based on selected vibe (local playlists)

## Tech Stack

### Backend
- Node.js
- TypeScript
- Express
- PostgreSQL
- Prisma ORM
- JWT authentication

### Mobile App
- Flutter
- Riverpod (state management)
- HTTP client
- Just Audio (audio player)

## Getting Started

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
# Create .env file with:
DATABASE_URL="postgresql://user:password@localhost:5432/vybgo?schema=public"
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
PORT=3000
```

4. Set up the database:
```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate
```

5. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Mobile App Setup

1. Navigate to the mobile directory:
```bash
cd mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update the API base URL in `lib/services/api_service.dart`:
   - For Android emulator: `http://10.0.2.2:3000/api`
   - For iOS simulator: `http://localhost:3000/api`
   - For physical device: Use your computer's IP address (e.g., `http://192.168.1.100:3000/api`)

4. Run the app:
```bash
flutter run
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user

### Vibes
- `GET /api/vibes` - Get all available vibes

### Rides (requires authentication)
- `POST /api/rides` - Create a new ride
- `GET /api/rides` - Get ride history
- `GET /api/rides/:id` - Get a specific ride
- `PATCH /api/rides/:id/status` - Update ride status

## Development Principles

- Build in small, incremental steps
- Keep code modular and clean for easy extension
- Run and fix errors after each step

## Next Steps (Future Phases)

- Driver app
- Real-time ride tracking
- Spotify integration
- Push notifications
- Payment integration
- Rating system

## License

ISC



