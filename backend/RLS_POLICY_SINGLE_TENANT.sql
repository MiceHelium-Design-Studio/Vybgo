-- VYBGO Single-Tenant RLS Policies
-- Apply these to Supabase PostgreSQL after migrations run
-- These enforce that each user can only see/modify their own data

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.music_tracks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can view only their own profile
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Users can update only their own profile
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users cannot delete themselves (optional: prevent accidental deletion)
-- Uncomment if you want to prevent self-deletion
-- CREATE POLICY "Users cannot delete own profile"
--   ON public.users FOR DELETE
--   USING (false);

-- Allow authenticated users to insert their own record (signup)
CREATE POLICY "Users can create own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- RIDES TABLE POLICIES
-- Single-tenant: user can only see/edit their own rides
-- ============================================================================

-- Users can view only their own rides
CREATE POLICY "Users can view own rides"
  ON public.rides FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create rides (user_id is forced to auth.uid() in app)
CREATE POLICY "Users can create own rides"
  ON public.rides FOR INSERT
  WITH CHECK (
    auth.uid() = user_id  -- Enforce authenticated user is the ride owner
  );

-- Users can update only their own rides (status, location, etc.)
CREATE POLICY "Users can update own rides"
  ON public.rides FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete only their own rides
CREATE POLICY "Users can delete own rides"
  ON public.rides FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- DRIVERS TABLE POLICIES
-- Note: In single-tenant model, each driver is a separate user
-- If drivers are a separate entity, apply similar policies
-- ============================================================================

-- Drivers can view only their own profile
CREATE POLICY "Drivers can view own profile"
  ON public.drivers FOR SELECT
  USING (auth.uid() = id);

-- Drivers can create their own profile
CREATE POLICY "Drivers can create own profile"
  ON public.drivers FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Drivers can update their own profile
CREATE POLICY "Drivers can update own profile"
  ON public.drivers FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- DRIVES TABLE POLICIES
-- Single-tenant: driver can only see/edit their own drives
-- ============================================================================

-- Drivers can view only their own drives
CREATE POLICY "Drivers can view own drives"
  ON public.drives FOR SELECT
  USING (auth.uid() = driver_id);

-- Drivers can create drives for their own rides
CREATE POLICY "Drivers can create own drives"
  ON public.drives FOR INSERT
  WITH CHECK (auth.uid() = driver_id);

-- Drivers can update only their own drives
CREATE POLICY "Drivers can update own drives"
  ON public.drives FOR UPDATE
  USING (auth.uid() = driver_id)
  WITH CHECK (auth.uid() = driver_id);

-- Drivers can delete only their own drives
CREATE POLICY "Drivers can delete own drives"
  ON public.drives FOR DELETE
  USING (auth.uid() = driver_id);

-- ============================================================================
-- MUSIC_TRACKS TABLE POLICIES
-- Music tracks belong to either a ride or a drive (both owned by user_id/driver_id)
-- ============================================================================

-- For rides: user can view music tracks of their own rides
CREATE POLICY "Users can view music tracks of own rides"
  ON public.music_tracks FOR SELECT
  USING (
    ride_id IS NOT NULL AND
    ride_id IN (SELECT id FROM public.rides WHERE user_id = auth.uid())
  );

-- For drives: driver can view music tracks of their own drives
CREATE POLICY "Drivers can view music tracks of own drives"
  ON public.music_tracks FOR SELECT
  USING (
    drive_id IS NOT NULL AND
    drive_id IN (SELECT id FROM public.drives WHERE driver_id = auth.uid())
  );

-- Users can create music tracks for their own rides
CREATE POLICY "Users can create music tracks for own rides"
  ON public.music_tracks FOR INSERT
  WITH CHECK (
    ride_id IS NOT NULL AND
    ride_id IN (SELECT id FROM public.rides WHERE user_id = auth.uid())
  );

-- Drivers can create music tracks for their own drives
CREATE POLICY "Drivers can create music tracks for own drives"
  ON public.music_tracks FOR INSERT
  WITH CHECK (
    drive_id IS NOT NULL AND
    drive_id IN (SELECT id FROM public.drives WHERE driver_id = auth.uid())
  );

-- Users can update music tracks of their own rides
CREATE POLICY "Users can update music tracks of own rides"
  ON public.music_tracks FOR UPDATE
  USING (
    ride_id IS NOT NULL AND
    ride_id IN (SELECT id FROM public.rides WHERE user_id = auth.uid())
  )
  WITH CHECK (
    ride_id IS NOT NULL AND
    ride_id IN (SELECT id FROM public.rides WHERE user_id = auth.uid())
  );

-- Drivers can update music tracks of their own drives
CREATE POLICY "Drivers can update music tracks of own drives"
  ON public.music_tracks FOR UPDATE
  USING (
    drive_id IS NOT NULL AND
    drive_id IN (SELECT id FROM public.drives WHERE driver_id = auth.uid())
  )
  WITH CHECK (
    drive_id IS NOT NULL AND
    drive_id IN (SELECT id FROM public.drives WHERE driver_id = auth.uid())
  );

-- Users can delete music tracks of their own rides
CREATE POLICY "Users can delete music tracks of own rides"
  ON public.music_tracks FOR DELETE
  USING (
    ride_id IS NOT NULL AND
    ride_id IN (SELECT id FROM public.rides WHERE user_id = auth.uid())
  );

-- Drivers can delete music tracks of their own drives
CREATE POLICY "Drivers can delete music tracks of own drives"
  ON public.music_tracks FOR DELETE
  USING (
    drive_id IS NOT NULL AND
    drive_id IN (SELECT id FROM public.drives WHERE driver_id = auth.uid())
  );

-- ============================================================================
-- GRANT PERMISSIONS
-- Allow authenticated users to query tables
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rides TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.drivers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.drives TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.music_tracks TO authenticated;

-- Allow unauthenticated users to insert (for signup)
GRANT INSERT ON public.users TO anon;
