import express from 'express';
import prisma from '../prisma';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { simulateRideLifecycle, stopRideSimulation } from '../services/simulationService';
import { fcmService } from '../services/fcmService';
import { VibeTypeValues, RideStatusValues } from '../types/prismaCompat';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get ride history for authenticated user (must come before /:id)
router.get('/', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId;

    const rides = await prisma.ride.findMany({
      where: {
        userId: userId!,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.json(rides);
  } catch (error) {
    next(error);
  }
});

// Create a ride
router.post('/', async (req: AuthRequest, res, next) => {
  try {
    const { pickup, dropoff, vibe } = req.body;
    const userId = req.userId;

    if (!pickup || !dropoff || !vibe) {
      return res
        .status(400)
        .json({ error: 'Pickup, dropoff, and vibe are required' });
    }

    // Validate vibe
    const validVibes = VibeTypeValues;
    if (!validVibes.includes(vibe)) {
      return res.status(400).json({ error: 'Invalid vibe type' });
    }

    const ride = await prisma.ride.create({
      data: {
        userId: userId!,
        pickup,
        dropoff,
        vibe: vibe as any,
        status: 'PENDING' as any,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });

    // Start ride lifecycle simulation (non-blocking)
    simulateRideLifecycle(ride.id);

    res.status(201).json(ride);
  } catch (error) {
    next(error);
  }
});

// Get ride by ID (must come after /)
router.get('/:id', async (req: AuthRequest, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const ride = await prisma.ride.findFirst({
      where: {
        id,
        userId: userId!,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });

    if (!ride) {
      return res.status(404).json({ error: 'Ride not found' });
    }

    res.json(ride);
  } catch (error) {
    next(error);
  }
});

// Update ride status (for future driver app integration)
router.patch('/:id/status', async (req: AuthRequest, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = req.userId;

    if (!status) {
      return res.status(400).json({ error: 'Status is required' });
    }

    // Validate status
    const validStatuses = RideStatusValues;
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ride = await prisma.ride.findFirst({
      where: {
        id,
        userId: userId!,
      },
    });

    if (!ride) {
      return res.status(404).json({ error: 'Ride not found' });
    }

    const updatedRide = await prisma.ride.update({
      where: { id },
      data: { status: status as any },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },
      },
    });

    // Stop simulation if ride is cancelled or completed
    if (status === 'CANCELLED' || status === 'COMPLETED') {
      stopRideSimulation(id);
    }

    res.json(updatedRide);
  } catch (error) {
    next(error);
  }
});

// Admin: Send test push notification (for development/testing)
router.post('/admin/test-push', async (req: AuthRequest, res, next) => {
  try {
    const { rideId, status } = req.body;
    const userId = req.userId;

    // Get user's FCM token
    const user = await prisma.user.findUnique({
      where: { id: userId! },
      select: { fcmToken: true, name: true },
    });

    if (!user || !user.fcmToken) {
      return res.status(400).json({
        error: 'No FCM token found for this user. Register device first.',
      });
    }

    // Send test push
    const result = await fcmService.sendRideNotification(
      user.fcmToken,
      rideId || 'test-ride-123',
      status || 'accepted',
      'Test Driver'
    );

    res.json({
      message: 'Test push sent',
      result,
      note: 'Check your device for notification (might be in background)',
    });
  } catch (error) {
    next(error);
  }
});

export default router;

