# Supabase Deployment Guide for VYBGO

This guide walks you through deploying the VYBGO database schema and Row Level Security (RLS) policies to Supabase.

## Prerequisites
- Supabase project created at [supabase.com](https://supabase.com)
- Access to the Supabase SQL Editor
- Backend environment variables set (`.env` has `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`)

## Deployment Steps

### Step 1: Apply the Base Schema

1. Log in to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy the entire contents of `supabase-schema.sql` from this backend folder
6. Paste into the SQL Editor
7. Click **Run** (or Ctrl+Enter)
8. Wait for success message

Expected output: Tables `User`, `Driver`, `Ride`, `Drive`, `MusicTrack` created with indexes and constraints.

### Step 2: Verify Schema was Applied

1. Go to **Database** (left sidebar)
2. Expand **Tables**
3. You should see: `User`, `Driver`, `Ride`, `Drive`, `MusicTrack`
4. Click each table and verify columns match `prisma/schema.prisma`

### Step 3: Apply Row Level Security (RLS) Policies

1. Navigate to **SQL Editor** → **New Query**
2. Copy the entire contents of `RLS_POLICIES_COMPREHENSIVE.sql`
3. Paste into the SQL Editor
4. Click **Run**
5. Wait for success (you'll see "PostgreSQL query completed")

Expected output: All tables should have RLS enabled and policies created.

### Step 4: Verify RLS Policies

1. Go to **Authentication** (left sidebar) → **Policies**
2. You should see policies for each table:
   - `User`: ~6 policies (view own, update own, admin view/update, admin insert/delete)
   - `Ride`: ~6 policies (user CRUD, admin CRUD, status restrictions)
   - `Driver`: ~4 policies (driver CRUD, admin CRUD)
   - `Drive`: ~4 policies (driver view, driver update, admin view/update)
   - `MusicTrack`: ~5 policies (user CRUD for their rides, admin CRUD)

### Step 5: Create Test Admin User in Supabase

1. Go to **Authentication** (left sidebar) → **Users**
2. Click **Add user** (or use Supabase Auth API)
3. Create user:
   - Email: `raghidhilal@gmail.com`
   - Password: `Oldschool1*`
4. Once created, note the UUID
5. Navigate to **SQL Editor** → **New Query**
6. Run:
   ```sql
   UPDATE "User" SET "isAdmin" = true WHERE email = 'raghidhilal@gmail.com';
   ```
7. Click **Run** to set admin flag

### Step 6: Test Login via Backend

On your development machine (Windows), run:

```powershell
$resp = Invoke-RestMethod -Uri 'http://localhost:3001/api/auth/login' -Method Post -ContentType 'application/json' -Body (ConvertTo-Json @{ email = 'raghidhilal@gmail.com'; password = 'Oldschool1*' }) -UseBasicParsing

$resp | ConvertTo-Json -Depth 5
```

Expected: You should receive a JWT token and user object with `"isAdmin": true`.

### Step 7: Verify RLS Enforcement (Optional but Recommended)

1. Create two test users in Supabase Auth
2. Use each user's JWT to call:
   ```
   GET http://10.0.2.2:3001/api/auth/whoami
   Authorization: Bearer <JWT>
   ```
3. Verify each user can only see their own data
4. Create a ride as User A
5. Try to view that ride as User B (should fail or return empty due to RLS)

## Troubleshooting

### Issue: "Invalid `prisma.user.findUnique()` invocation" on local development
- **Cause**: Local SQLite doesn't support Postgres-only features (enums, RLS)
- **Solution**: The backend uses `prisma/schema.sqlite.prisma` for local dev with fallback types in `src/types/prismaCompat.ts`

### Issue: Policies not working after deployment
- **Cause**: RLS might not be enabled on tables
- **Check**: In Supabase Dashboard → **Authentication** → **Policies**, verify each table has RLS toggle **ON**

### Issue: "User `` was denied access" errors
- **Cause**: Missing user ID in JWT claims or RLS policy doesn't match `auth.uid()`
- **Solution**: Ensure backend JWT includes `userId` claim matching the Supabase `User` table `id` column

## Architecture Notes

### Single-Tenant Model
Every `Ride` is owned by a `User`. RLS ensures:
- Users can only see/modify their own rides
- Drivers can see the rides they're assigned to
- Admins can see and modify any ride (for support/debugging)

### Admin Bypass
The `isAdmin` flag allows superuser access for support/debugging:
- Admins can view all users, rides, drivers
- Admins can update any record
- Admins can delete records for cleanup

### Cascade Deletes
Foreign keys are configured with `onDelete: Cascade`:
- Deleting a `User` → cascades to delete their `Ride` records
- Deleting a `Ride` → cascades to delete `Drive` and `MusicTrack` records

## Next Steps

1. **Environment Variables**: Add to `.env` after Supabase deployment:
   ```
   DATABASE_URL=postgresql://user:password@db.xxx.supabase.co:5432/postgres?schema=public&sslmode=require
   DIRECT_URL=postgresql://user:password@db.xxx.supabase.co:5432/postgres?schema=public&sslmode=require
   SUPABASE_ANON_KEY=eyJ...
   SUPABASE_SERVICE_ROLE_KEY=eyJ...
   ```

2. **Switch Backend to Postgres**: After testing locally with SQLite, update backend to use Postgres by:
   - Running `npx prisma generate --schema=prisma/schema.prisma`
   - Rebuilding with `npm run build`
   - Restarting server with `DATABASE_URL` pointing to Supabase Postgres

3. **Deploy Backend**: Use Docker or your preferred platform (Railway, Vercel, Heroku, AWS, etc.)

4. **Mobile Testing**: Update Flutter app to use your production backend URL instead of `http://10.0.2.2:3001/api`

## Additional Resources

- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase SQL Editor Guide](https://supabase.com/docs/guides/sql-editor)
- [Prisma Supabase Setup](https://www.prisma.io/docs/orm/overview/databases/supabase)
