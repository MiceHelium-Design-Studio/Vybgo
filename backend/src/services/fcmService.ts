import axios from 'axios';
import { env } from '../config/env';

/**
 * Firebase Cloud Messaging (FCM) Service
 * 
 * Sends push notifications to Android/iOS devices via FCM.
 * 
 * Setup required:
 * 1. Get FCM Server API Key from Firebase Console:
 *    - Go to Firebase Console → Project Settings → Cloud Messaging tab
 *    - Copy "Server API Key"
 * 2. Add to .env:
 *    FCM_SERVER_API_KEY=your_server_api_key_here
 * 3. Restart backend
 */

interface FCMMessage {
  token: string; // Device FCM token
  notification?: {
    title: string;
    body: string;
  };
  data?: Record<string, string>;
  android?: {
    priority?: 'high' | 'normal';
    ttl?: string; // e.g. "3600s"
  };
  apns?: {
    headers?: Record<string, string>;
    payload?: {
      aps: {
        alert?: {
          title: string;
          body: string;
        };
        sound: string;
        badge?: number;
      };
    };
  };
}

class FCMService {
  private serverApiKey: string | undefined;
  private fcmEndpoint = 'https://fcm.googleapis.com/v1/projects';

  constructor() {
    this.serverApiKey = process.env.FCM_SERVER_API_KEY;
  }

  /**
   * Check if FCM is configured
   */
  isConfigured(): boolean {
    return !!this.serverApiKey;
  }

  /**
   * Send a push notification to a single device
   */
  async sendNotification(
    deviceToken: string,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    if (!this.isConfigured()) {
      return {
        success: false,
        error: 'FCM is not configured. Add FCM_SERVER_API_KEY to .env',
      };
    }

    try {
      const message: FCMMessage = {
        token: deviceToken,
        notification: { title, body },
        data: data || {},
        android: {
          priority: 'high',
          ttl: '3600s',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // For this example, we use the legacy FCM HTTP API
      // In production, use the newer Google Cloud Messaging API with OAuth 2.0
      const response = await axios.post(
        'https://fcm.googleapis.com/fcm/send',
        {
          to: deviceToken,
          notification: {
            title,
            body,
          },
          data: data || {},
          priority: 'high',
          android: {
            priority: 'high',
          },
        },
        {
          headers: {
            Authorization: `key=${this.serverApiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.data.success === 1) {
        return {
          success: true,
          messageId: response.data.multicast_id,
        };
      } else {
        return {
          success: false,
          error: response.data.failure ? 'Device token invalid or unregistered' : 'Unknown error',
        };
      }
    } catch (error: any) {
      console.error('[FCM] Error sending notification:', error.message);
      return {
        success: false,
        error: error.message || 'Failed to send notification',
      };
    }
  }

  /**
   * Send notifications to multiple devices
   */
  async sendMulticast(
    deviceTokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<{
    success: boolean;
    successCount?: number;
    failureCount?: number;
    messageId?: string;
    errors?: string[];
  }> {
    if (!this.isConfigured()) {
      return {
        success: false,
        errors: ['FCM is not configured'],
      };
    }

    if (deviceTokens.length === 0) {
      return {
        success: false,
        errors: ['No device tokens provided'],
      };
    }

    // FCM legacy API doesn't support multicast directly
    // Send individually for now (in production, use Google Cloud Messaging API with batching)
    const results = await Promise.all(
      deviceTokens.map((token) =>
        this.sendNotification(token, title, body, data)
      )
    );

    const successCount = results.filter((r) => r.success).length;
    const failureCount = results.filter((r) => !r.success).length;
    const errors = results
      .filter((r) => !r.success && r.error)
      .map((r) => r.error as string);

    return {
      success: failureCount === 0,
      successCount,
      failureCount,
      errors: errors.length > 0 ? errors : undefined,
    };
  }

  /**
   * Send a ride-related push notification
   */
  async sendRideNotification(
    deviceToken: string,
    rideId: string,
    status: 'accepted' | 'completed' | 'cancelled' | 'updated',
    driverName?: string
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    const messages: Record<string, { title: string; body: string }> = {
      accepted: {
        title: 'Ride Accepted',
        body: driverName ? `${driverName} has accepted your ride` : 'Your ride has been accepted',
      },
      completed: {
        title: 'Ride Completed',
        body: 'Your ride is complete. Thank you for using VYBGO!',
      },
      cancelled: {
        title: 'Ride Cancelled',
        body: 'Your ride has been cancelled',
      },
      updated: {
        title: 'Ride Update',
        body: 'Your ride status has been updated',
      },
    };

    const message = messages[status] || messages.updated;

    return this.sendNotification(deviceToken, message.title, message.body, {
      type: 'ride_status_update',
      rideId,
      status,
    });
  }
}

export const fcmService = new FCMService();
