# RLS Policy Performance Fix

## Problem

The Supabase advisor detected a performance issue with the RLS policy on the `User` table:

> Table public.User has a row level security policy that re-evaluates `auth.uid()` for each row. This produces suboptimal query performance at scale.

## Root Cause

When an RLS policy uses `auth.uid()` directly, PostgreSQL evaluates it for **every row** in the table during query execution. This causes performance degradation, especially as the table grows.

## Solution

Wrap `auth.uid()` in a subquery: `(SELECT auth.uid())`. This evaluates the function **once per query** instead of once per row.

### Before (Slow):
```sql
CREATE POLICY "Users can update own profile"
ON "public"."User"
FOR UPDATE
USING (id = auth.uid());  -- ❌ Evaluated for each row
```

### After (Fast):
```sql
CREATE POLICY "Users can update own profile"
ON "public"."User"
FOR UPDATE
USING (id = (SELECT auth.uid()));  -- ✅ Evaluated once per query
```

## How to Apply the Fix

### Option 1: Supabase Dashboard (Recommended) ⭐

1. Open your Supabase project dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor** (left sidebar)
4. Click **New query**
5. Copy and paste the contents of `prisma/migrations/fix_user_rls_policy.sql`
6. Click **Run** (or press Ctrl+Enter) to execute the migration
7. You should see "Success. No rows returned"

**Quick Copy-Paste:**
```sql
-- Drop existing RLS policy if it exists
DROP POLICY IF EXISTS "Users can update own profile" ON "public"."User";

-- Create optimized RLS policy using subquery
CREATE POLICY "Users can update own profile"
ON "public"."User"
FOR UPDATE
USING (id = (SELECT auth.uid()))
WITH CHECK (id = (SELECT auth.uid()));

-- Also fix SELECT policy if it exists
DROP POLICY IF EXISTS "Users can view own profile" ON "public"."User";
CREATE POLICY "Users can view own profile"
ON "public"."User"
FOR SELECT
USING (id = (SELECT auth.uid()));

-- Fix INSERT policy if it exists
DROP POLICY IF EXISTS "Users can insert own profile" ON "public"."User";
CREATE POLICY "Users can insert own profile"
ON "public"."User"
FOR INSERT
WITH CHECK (id = (SELECT auth.uid()));
```

### Option 2: Supabase CLI

```bash
# If you have Supabase CLI installed
cd backend
supabase db push prisma/migrations/fix_user_rls_policy.sql
```

### Option 3: Direct Database Connection

```bash
# Connect to your Supabase database
psql "your-database-connection-string"

# Then run the SQL file
\i prisma/migrations/fix_user_rls_policy.sql
```

## Verification

After applying the fix:

1. Go to Supabase Dashboard → **Authentication** → **Policies**
2. Check the `User` table policies
3. Verify the policies use `(SELECT auth.uid())` instead of `auth.uid()`
4. The Supabase advisor should no longer show this warning

## Additional Notes

- This fix applies to all RLS policies that use `auth.uid()` or `auth.jwt()`
- The same pattern should be applied to other tables if they have similar policies
- Performance improvement will be most noticeable with large datasets (1000+ rows)

## Related Documentation

- [Supabase RLS Performance Best Practices](https://supabase.com/docs/guides/database/postgres/row-level-security#performance)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

