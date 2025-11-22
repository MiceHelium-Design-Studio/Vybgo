# VYBGO Backend API

Backend API for the VYBGO ride-hailing app.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your database URL and JWT secret
```

3. Set up the database:
```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate
```

4. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

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

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `PORT` - Server port (default: 3000)



