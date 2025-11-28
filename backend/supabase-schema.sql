-- VYBGO Supabase Schema - PostgreSQL DDL
-- Run this SQL directly in Supabase SQL Editor

-- Create enums
CREATE TYPE vibe_type AS ENUM ('CHILL', 'UPBEAT', 'FOCUS', 'PARTY', 'NOSTALGIC');
CREATE TYPE ride_status AS ENUM ('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  is_admin BOOLEAN DEFAULT false,
  password_hash VARCHAR(255),
  phone_number VARCHAR(20),
  profile_photo TEXT,
  fcm_token TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY,
  license_number VARCHAR(50) UNIQUE NOT NULL,
  vehicle_model VARCHAR(100),
  license_plate VARCHAR(20),
  verification_status VARCHAR(50) DEFAULT 'UNVERIFIED',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create rides table
CREATE TABLE IF NOT EXISTS rides (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  destination VARCHAR(255),
  ride_type VARCHAR(50),
  status ride_status DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create drives table
CREATE TABLE IF NOT EXISTS drives (
  id UUID PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  ride_id UUID NOT NULL UNIQUE REFERENCES rides(id) ON DELETE CASCADE,
  status ride_status DEFAULT 'PENDING',
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create music_tracks table
CREATE TABLE IF NOT EXISTS music_tracks (
  id UUID PRIMARY KEY,
  ride_id UUID REFERENCES rides(id) ON DELETE CASCADE,
  drive_id UUID REFERENCES drives(id) ON DELETE CASCADE,
  track_name VARCHAR(255),
  artist VARCHAR(255),
  album_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_ride_user_id ON rides(user_id);
CREATE INDEX idx_drive_driver_id ON drives(driver_id);
CREATE INDEX idx_music_ride_id ON music_tracks(ride_id);
CREATE INDEX idx_music_drive_id ON music_tracks(drive_id);

-- Optional: Create a test user
INSERT INTO users (id, email, name, password_hash)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'test@example.com',
  'Test User',
  '$2a$10$dummy.hash.placeholder'
) ON CONFLICT DO NOTHING;
