import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import authRoutes from './routes/auth';
import vibeRoutes from './routes/vibes';
import rideRoutes from './routes/rides';
import userRoutes from './routes/users';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Root endpoint - must be registered before other routes
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'VYBGO API Server',
    version: '1.0.0',
    api: '/api',
    endpoints: {
      root: '/',
      api: '/api',
      auth: '/api/auth',
      vibes: '/api/vibes',
      rides: '/api/rides',
        users: '/api/users',
      health: '/api/health'
    }
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/vibes', vibeRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/users', userRoutes);

// Root API endpoint
app.get('/api', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'VYBGO API is running',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      vibes: '/api/vibes',
      rides: '/api/rides',
        users: '/api/users',
      health: '/api/health'
    }
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'VYBGO API is running' });
});

// Error handling middleware (must be last)
app.use(errorHandler);

app.listen(env.port, () => {
  console.log(`🚗 VYBGO API server running on port ${env.port}`);
});


