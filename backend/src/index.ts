import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import authRoutes from './routes/auth';
import vibeRoutes from './routes/vibes';
import rideRoutes from './routes/rides';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/vibes', vibeRoutes);
app.use('/api/rides', rideRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'VYBGO API is running' });
});

// Error handling middleware (must be last)
app.use(errorHandler);

app.listen(env.port, () => {
  console.log(`🚗 VYBGO API server running on port ${env.port}`);
});


