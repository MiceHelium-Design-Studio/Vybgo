-- ============================================================================
-- VYBGO RLS (Row Level Security) Policies - Comprehensive
-- ============================================================================
-- This script enforces single-tenant data isolation and role-based access control.
-- Apply this in Supabase SQL Editor after deploying the base schema.
--
-- Key principles:
-- 1. Single-tenant: Users can only access their own data
-- 2. Admin override: Admins can access all data for support/debugging
-- 3. Explicit deny: Default deny unless a policy explicitly allows
-- ============================================================================

-- ============================================================================
-- 1. Enable Row Level Security on all tables
-- ============================================================================
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Driver" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Ride" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Drive" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MusicTrack" ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. USER TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON "User"
  FOR SELECT
  USING (auth.uid()::text = id OR EXISTS (
    SELECT 1 FROM "User" 
    WHERE id = auth.uid()::text AND "isAdmin" = true
  ));

-- Users can update their own profile (except isAdmin flag)
CREATE POLICY "Users can update their own profile" ON "User"
  FOR UPDATE
  USING (auth.uid()::text = id)
  WITH CHECK (
    auth.uid()::text = id 
    AND "isAdmin" = (SELECT "isAdmin" FROM "User" WHERE id = auth.uid()::text)
  );

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON "User"
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can update any user (including isAdmin flag for admin operations)
CREATE POLICY "Admins can update any user" ON "User"
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Only admins can insert new users (or the user_creation function)
CREATE POLICY "Admins can insert users" ON "User"
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
    OR auth.uid()::text = id -- Allow self-registration (will be replaced by auth trigger)
  );

-- Only admins can delete users
CREATE POLICY "Admins can delete users" ON "User"
  FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- ============================================================================
-- 3. RIDE TABLE POLICIES (Single-tenant per user)
-- ============================================================================

-- Users can view their own rides
CREATE POLICY "Users can view their own rides" ON "Ride"
  FOR SELECT
  USING (
    auth.uid()::text = "user_id"
    OR EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Users can create rides for themselves
CREATE POLICY "Users can create their own rides" ON "Ride"
  FOR INSERT
  WITH CHECK (
    auth.uid()::text = "user_id"
  );

-- Users can update their own rides (if not completed/cancelled)
CREATE POLICY "Users can update their own rides" ON "Ride"
  FOR UPDATE
  USING (
    auth.uid()::text = "user_id"
    AND status NOT IN ('COMPLETED', 'CANCELLED')
  )
  WITH CHECK (
    auth.uid()::text = "user_id"
    AND status NOT IN ('COMPLETED', 'CANCELLED')
  );

-- Admins can view all rides
CREATE POLICY "Admins can view all rides" ON "Ride"
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can update any ride (including status transitions)
CREATE POLICY "Admins can update any ride" ON "Ride"
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can delete any ride (for cleanup)
CREATE POLICY "Admins can delete any ride" ON "Ride"
  FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- ============================================================================
-- 4. DRIVER TABLE POLICIES
-- ============================================================================

-- Drivers can view their own profile
CREATE POLICY "Drivers can view their own profile" ON "Driver"
  FOR SELECT
  USING (auth.uid()::text = id);

-- Drivers can update their own profile
CREATE POLICY "Drivers can update their own profile" ON "Driver"
  FOR UPDATE
  USING (auth.uid()::text = id)
  WITH CHECK (auth.uid()::text = id);

-- Admins can view all drivers
CREATE POLICY "Admins can view all drivers" ON "Driver"
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can update any driver
CREATE POLICY "Admins can update any driver" ON "Driver"
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- ============================================================================
-- 5. DRIVE TABLE POLICIES (Associated with rides; drivers and ride owners can view)
-- ============================================================================

-- Drivers can view their own drives
CREATE POLICY "Drivers can view their own drives" ON "Drive"
  FOR SELECT
  USING (
    auth.uid()::text = "driverId"
    OR EXISTS (
      SELECT 1 FROM "Ride" 
      WHERE "Ride".id = "Drive"."rideId" AND "Ride"."user_id" = auth.uid()::text
    )
    OR EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Drivers can update their own drives (status transitions)
CREATE POLICY "Drivers can update their own drives" ON "Drive"
  FOR UPDATE
  USING (auth.uid()::text = "driverId")
  WITH CHECK (auth.uid()::text = "driverId");

-- Admins can view all drives
CREATE POLICY "Admins can view all drives" ON "Drive"
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can update any drive
CREATE POLICY "Admins can update any drive" ON "Drive"
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- ============================================================================
-- 6. MUSICTRACK TABLE POLICIES (Associated with rides/drives)
-- ============================================================================

-- Users can view music tracks in their rides
CREATE POLICY "Users can view music tracks in their rides" ON "MusicTrack"
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Ride" 
      WHERE "Ride".id = "MusicTrack"."ride_id" AND "Ride"."user_id" = auth.uid()::text
    )
    OR EXISTS (
        SELECT 1 FROM "Drive" 
        WHERE "Drive".id = "MusicTrack"."drive_id" AND "Drive"."driverId" = auth.uid()::text
    )
    OR EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Users can create music tracks in their rides
CREATE POLICY "Users can create music tracks in their rides" ON "MusicTrack"
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Ride" 
      WHERE "Ride".id = "MusicTrack"."ride_id" AND "Ride"."user_id" = auth.uid()::text
    )
  );

-- Users can update music tracks in their rides
CREATE POLICY "Users can update music tracks in their rides" ON "MusicTrack"
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM "Ride" 
      WHERE "Ride".id = "MusicTrack"."ride_id" AND "Ride"."user_id" = auth.uid()::text
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Ride" 
      WHERE "Ride".id = "MusicTrack"."ride_id" AND "Ride"."user_id" = auth.uid()::text
    )
  );

-- Admins can view all music tracks
CREATE POLICY "Admins can view all music tracks" ON "MusicTrack"
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- Admins can update any music track
CREATE POLICY "Admins can update any music track" ON "MusicTrack"
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM "User" WHERE id = auth.uid()::text AND "isAdmin" = true)
  );

-- ============================================================================
-- 7. VALIDATION & TESTING
-- ============================================================================
-- After applying these policies, test by:
--
-- 1. Log in as a normal user and verify you can only see your own data:
--    SELECT * FROM "Ride" WHERE "userId" = current_user_id;
--
-- 2. Try to access another user's ride (should return empty):
--    SELECT * FROM "Ride" WHERE "userId" = other_user_id;
--
-- 3. Log in as an admin and verify you can see all data:
--    SELECT * FROM "Ride";
--
-- 4. Verify cascade deletes work (delete a user, rides should cascade):
--    DELETE FROM "User" WHERE id = test_user_id;
--    SELECT * FROM "Ride" WHERE "userId" = test_user_id; -- Should be empty
--
-- ============================================================================
