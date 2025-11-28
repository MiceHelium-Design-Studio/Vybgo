import prisma from '../prisma';
import { RideStatusValues } from '../types/prismaCompat';

// Store active timers to allow cancellation if needed
const activeTimers = new Map<string, NodeJS.Timeout[]>();

/**
 * Update ride status in the database
 */
async function updateRideStatus(rideId: string, status: string): Promise<void> {
  try {
    // Check if ride still exists and is not already completed/cancelled
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      select: { status: true },
    });

    if (!ride) {
      console.log(`Ride ${rideId} not found, skipping status update`);
      return;
    }

    // Don't update if ride is already completed or cancelled
    if (ride.status === 'COMPLETED' || ride.status === 'CANCELLED') {
      console.log(`Ride ${rideId} is already ${ride.status}, stopping simulation`);
      // Clear any remaining timers
      clearTimers(rideId);
      return;
    }

    // Update the ride status
    await prisma.ride.update({
      where: { id: rideId },
      data: { status },
    });

    console.log(`✅ Ride ${rideId} status updated to ${status}`);

    // If completed, clear timers
    if (status === 'COMPLETED') {
      clearTimers(rideId);
    }
  } catch (error) {
    console.error(`Error updating ride ${rideId} status:`, error);
  }
}

/**
 * Clear all timers for a ride
 */
function clearTimers(rideId: string): void {
  const timers = activeTimers.get(rideId);
  if (timers) {
    timers.forEach((timer) => clearTimeout(timer));
    activeTimers.delete(rideId);
  }
}

/**
 * Simulate the ride lifecycle: PENDING → ACCEPTED → IN_PROGRESS → COMPLETED
 * 
 * Timing:
 * - 5 seconds: ACCEPTED
 * - 15 seconds: IN_PROGRESS
 * - 30 seconds: COMPLETED
 */
export function simulateRideLifecycle(rideId: string): void {
  const timers: NodeJS.Timeout[] = [];

  // After 5 seconds: ACCEPTED
  const timer1 = setTimeout(async () => {
    await updateRideStatus(rideId, 'ACCEPTED');
  }, 5000);
  timers.push(timer1);

  // After 15 seconds: IN_PROGRESS
  const timer2 = setTimeout(async () => {
    await updateRideStatus(rideId, 'IN_PROGRESS');
  }, 15000);
  timers.push(timer2);

  // After 30 seconds: COMPLETED
  const timer3 = setTimeout(async () => {
    await updateRideStatus(rideId, 'COMPLETED');
    // Clear timers after completion
    clearTimers(rideId);
  }, 30000);
  timers.push(timer3);

  // Store timers for potential cancellation
  activeTimers.set(rideId, timers);

  console.log(`🚗 Started simulation for ride ${rideId}`);
}

/**
 * Stop simulation for a ride (e.g., if user cancels)
 */
export function stopRideSimulation(rideId: string): void {
  clearTimers(rideId);
  console.log(`🛑 Stopped simulation for ride ${rideId}`);
}


