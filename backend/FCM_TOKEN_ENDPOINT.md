# FCM Token Endpoint Documentation

## Overview

The FCM (Firebase Cloud Messaging) token endpoint allows users to register their device tokens for push notifications.

## Endpoints

### POST /api/users/fcm-token

Register or update the FCM token for the authenticated user.

**Authentication:** Required (Bearer token)

**Request Body:**
```json
{
  "token": "fcm-device-token-string"
}
```

**Response (200 OK):**
```json
{
  "message": "FCM token updated successfully",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "name": "User Name",
    "fcmToken": "fcm-device-token-string",
    "updatedAt": "2025-01-22T10:00:00.000Z"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Missing or invalid token
- `401 Unauthorized`: Missing or invalid authentication token

### GET /api/users/fcm-token

Get the current user's FCM token (for debugging).

**Authentication:** Required (Bearer token)

**Response (200 OK):**
```json
{
  "fcmToken": "fcm-device-token-string"
}
```

### DELETE /api/users/fcm-token

Clear/remove the FCM token for the authenticated user.

**Authentication:** Required (Bearer token)

**Response (200 OK):**
```json
{
  "message": "FCM token cleared successfully"
}
```

## Usage Example

### cURL

```bash
# Register FCM token
curl -X POST http://localhost:3000/api/users/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "fcm-device-token-here"}'

# Get FCM token
curl -X GET http://localhost:3000/api/users/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Clear FCM token
curl -X DELETE http://localhost:3000/api/users/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### JavaScript/TypeScript

```typescript
// Register FCM token
const response = await fetch('http://localhost:3000/api/users/fcm-token', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    token: fcmToken,
  }),
});

const data = await response.json();
```

## Database Schema

The `User` table now includes an `fcmToken` field:

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  phone     String?  @unique
  password  String
  name      String?
  fcmToken  String?  // Firebase Cloud Messaging token
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  rides     Ride[]
}
```

## Migration

To apply the database schema change, run:

```sql
ALTER TABLE "User" 
ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;
```

Or use Prisma:

```bash
npx prisma db push
# or
npx prisma migrate dev --name add_fcm_token
```

## Integration with Mobile App

The Flutter app's `NotificationService` automatically calls this endpoint when:
1. FCM token is generated after user login
2. FCM token is refreshed

The service passes the authentication token in the Authorization header.

## Notes

- FCM tokens can change over time (e.g., app reinstall, token refresh)
- The endpoint updates the token if it already exists
- One token per user (for multi-device support, consider a Device table)
- Tokens are nullable - users without tokens won't receive push notifications

