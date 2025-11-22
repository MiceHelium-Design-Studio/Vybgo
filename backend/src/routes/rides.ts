import express from 'express';
import { VibeType, RideStatus } from '@prisma/client';
import prisma from '../prisma';
import { authenticateToken, AuthRequest } from '../middleware/auth';
import { simulateRideLifecycle, stopRideSimulation } from '../services/simulationService';

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
    const validVibes = Object.values(VibeType);
    if (!validVibes.includes(vibe)) {
      return res.status(400).json({ error: 'Invalid vibe type' });
    }

    const ride = await prisma.ride.create({
      data: {
        userId: userId!,
        pickup,
        dropoff,
        vibe: vibe as VibeType,
        status: RideStatus.PENDING,
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
    const validStatuses = Object.values(RideStatus);
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
      data: { status: status as RideStatus },
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
    if (status === RideStatus.CANCELLED || status === RideStatus.COMPLETED) {
      stopRideSimulation(id);
    }

    res.json(updatedRide);
  } catch (error) {
    next(error);
  }
});

export default router;

