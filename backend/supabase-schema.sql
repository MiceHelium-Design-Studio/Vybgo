-- VYBGO Supabase Schema - PostgreSQL DDL
-- Run this SQL directly in Supabase SQL Editor

-- Create enums
CREATE TYPE vibe_type AS ENUM ('CHILL', 'UPBEAT', 'FOCUS', 'PARTY', 'NOSTALGIC');
CREATE TYPE ride_status AS ENUM ('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- Create users table
CREATE TABLE IF NOT EXISTS "User" (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  "isAdmin" BOOLEAN DEFAULT false,
  "passwordHash" VARCHAR(255),
  "phoneNumber" VARCHAR(20),
  "profilePhoto" TEXT,
  "fcmToken" TEXT,
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create drivers table
CREATE TABLE IF NOT EXISTS "Driver" (
  id UUID PRIMARY KEY,
  "licenseNumber" VARCHAR(50) UNIQUE NOT NULL,
  "vehicleModel" VARCHAR(100),
  "licensePlate" VARCHAR(20),
  "verificationStatus" VARCHAR(50) DEFAULT 'UNVERIFIED',
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create rides table
CREATE TABLE IF NOT EXISTS "Ride" (
  id UUID PRIMARY KEY,
  "user_id" UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
  destination VARCHAR(255),
  "rideType" VARCHAR(50),
  status ride_status DEFAULT 'PENDING',
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create drives table
CREATE TABLE IF NOT EXISTS "Drive" (
  id UUID PRIMARY KEY,
  "driverId" UUID NOT NULL REFERENCES "Driver"(id) ON DELETE CASCADE,
  "rideId" UUID NOT NULL UNIQUE REFERENCES "Ride"(id) ON DELETE CASCADE,
  status ride_status DEFAULT 'PENDING',
  "startedAt" TIMESTAMP,
  "completedAt" TIMESTAMP,
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create music_tracks table
CREATE TABLE IF NOT EXISTS "MusicTrack" (
  id UUID PRIMARY KEY,
  "ride_id" UUID REFERENCES "Ride"(id) ON DELETE CASCADE,
  "drive_id" UUID REFERENCES "Drive"(id) ON DELETE CASCADE,
  "trackName" VARCHAR(255),
  artist VARCHAR(255),
  "albumUrl" TEXT,
  "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_ride_user_id ON "Ride"("user_id");
CREATE INDEX idx_drive_driver_id ON "Drive"("driverId");
CREATE INDEX idx_music_ride_id ON "MusicTrack"("ride_id");
CREATE INDEX idx_music_drive_id ON "MusicTrack"("drive_id");

-- Optional: Create a test user
INSERT INTO "User" (id, email, name, "passwordHash")
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'test@example.com',
  'Test User',
  '$2a$10$dummy.hash.placeholder'
) ON CONFLICT DO NOTHING;
