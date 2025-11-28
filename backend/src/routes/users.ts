import express from 'express';
import prisma from '../prisma';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Update FCM token for authenticated user
router.post('/fcm-token', async (req: AuthRequest, res, next) => {
  try {
    const { token } = req.body;
    const userId = req.userId;

    if (!token || typeof token !== 'string') {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Update user's FCM token
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: token },
      select: {
        id: true,
        email: true,
        name: true,
        fcmToken: true,
        updatedAt: true,
      },
    });

    res.json({
      message: 'FCM token updated successfully',
      user: updatedUser,
    });
  } catch (error) {
    next(error);
  }
});

// Get current user's FCM token (optional - for debugging)
router.get('/fcm-token', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fcmToken: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      fcmToken: user.fcmToken,
    });
  } catch (error) {
    next(error);
  }
});

// Delete/clear FCM token
router.delete('/fcm-token', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null },
    });

    res.json({
      message: 'FCM token cleared successfully',
    });
  } catch (error) {
    next(error);
  }
});

export default router;

