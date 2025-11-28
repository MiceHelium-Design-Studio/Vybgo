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
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE drives ENABLE ROW LEVEL SECURITY;
ALTER TABLE music_tracks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. USER TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT
  USING (auth.uid() = id OR EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND is_admin = true
  ));

-- Users can update their own profile (except isAdmin flag)
CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND is_admin = (SELECT is_admin FROM users WHERE id = auth.uid())
  );

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update any user (including isAdmin flag for admin operations)
CREATE POLICY "Admins can update any user" ON users
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Only admins can insert new users (or the user_creation function)
CREATE POLICY "Admins can insert users" ON users
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    OR auth.uid() = id -- Allow self-registration (will be replaced by auth trigger)
  );

-- Only admins can delete users
CREATE POLICY "Admins can delete users" ON users
  FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- ============================================================================
-- 3. RIDE TABLE POLICIES (Single-tenant per user)
-- ============================================================================

-- Users can view their own rides
CREATE POLICY "Users can view their own rides" ON rides
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Users can create rides for themselves
CREATE POLICY "Users can create their own rides" ON rides
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
  );

-- Users can update their own rides (if not completed/cancelled)
CREATE POLICY "Users can update their own rides" ON rides
  FOR UPDATE
  USING (
    auth.uid() = user_id
    AND status NOT IN ('COMPLETED', 'CANCELLED')
  )
  WITH CHECK (
    auth.uid() = user_id
    AND status NOT IN ('COMPLETED', 'CANCELLED')
  );

-- Admins can view all rides
CREATE POLICY "Admins can view all rides" ON rides
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update any ride (including status transitions)
CREATE POLICY "Admins can update any ride" ON rides
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can delete any ride (for cleanup)
CREATE POLICY "Admins can delete any ride" ON rides
  FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- ============================================================================
-- 4. DRIVER TABLE POLICIES
-- ============================================================================

-- Drivers can view their own profile
CREATE POLICY "Drivers can view their own profile" ON drivers
  FOR SELECT
  USING (auth.uid() = id);

-- Drivers can update their own profile
CREATE POLICY "Drivers can update their own profile" ON drivers
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can view all drivers
CREATE POLICY "Admins can view all drivers" ON drivers
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update any driver
CREATE POLICY "Admins can update any driver" ON drivers
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- ============================================================================
-- 5. DRIVE TABLE POLICIES (Associated with rides; drivers and ride owners can view)
-- ============================================================================

-- Drivers can view their own drives
CREATE POLICY "Drivers can view their own drives" ON drives
  FOR SELECT
  USING (
    auth.uid() = driver_id
    OR EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = drives.ride_id AND rides.user_id = auth.uid()
    )
    OR EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Drivers can update their own drives (status transitions)
CREATE POLICY "Drivers can update their own drives" ON drives
  FOR UPDATE
  USING (auth.uid() = driver_id)
  WITH CHECK (auth.uid() = driver_id);

-- Admins can view all drives
CREATE POLICY "Admins can view all drives" ON drives
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update any drive
CREATE POLICY "Admins can update any drive" ON drives
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- ============================================================================
-- 6. MUSICTRACK TABLE POLICIES (Associated with rides/drives)
-- ============================================================================

-- Users can view music tracks in their rides
CREATE POLICY "Users can view music tracks in their rides" ON music_tracks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = music_tracks.ride_id AND rides.user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM drives 
        WHERE drives.id = music_tracks.drive_id AND drives.driver_id = auth.uid()
    )
    OR EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Users can create music tracks in their rides
CREATE POLICY "Users can create music tracks in their rides" ON music_tracks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = music_tracks.ride_id AND rides.user_id = auth.uid()
    )
  );

-- Users can update music tracks in their rides
CREATE POLICY "Users can update music tracks in their rides" ON music_tracks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = music_tracks.ride_id AND rides.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = music_tracks.ride_id AND rides.user_id = auth.uid()
    )
  );

-- Admins can view all music tracks
CREATE POLICY "Admins can view all music tracks" ON music_tracks
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update any music track
CREATE POLICY "Admins can update any music track" ON music_tracks
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
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
