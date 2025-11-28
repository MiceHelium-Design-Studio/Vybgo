# 🔌 Supabase Connection Troubleshooting

## Current Issue: Can't Reach Database Server

**Error**: `P1001: Can't reach database server at db.bkltwqmkajwhatnyzogs.supabase.co:5432`

## Possible Causes & Solutions

### 1. **Supabase Database is Paused** (Most Common on Free Tier)

Supabase free tier databases pause after 1 week of inactivity.

**Solution:**

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. If database is paused, click **"Restore"** or **"Resume"**
4. Wait 1-2 minutes for database to start
5. Try connection again

### 2. **IP Address Not Whitelisted**

Supabase may require your IP to be whitelisted.

**Solution:**

1. Go to Supabase Dashboard → **Settings** → **Database**
2. Check **"Connection Pooling"** settings
3. Add your current IP address to whitelist
4. Or disable IP restrictions temporarily for testing

### 3. **Incorrect Connection String**

The connection string format might be incorrect.

**Solution:**

1. Go to Supabase Dashboard → **Settings** → **Database**
2. Copy the **"Connection string"** directly
3. It should look like:

   ```text
   postgresql://postgres.xxx:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```

4. Or for direct connection:

   ```text
   postgresql://postgres.xxx:[YOUR-PASSWORD]@db.xxx.supabase.co:5432/postgres
   ```

### 4. **Password Special Characters**

Special characters in password need URL encoding.

**Current password**: `[ABCVYBGO123*!]`

**URL-encoded**: `%5BABCVYBGO123%2A%21%5D`

**Solution:**

- Use the connection string from Supabase dashboard (it handles encoding)
- Or manually encode special characters:
  - `[` = `%5B`
  - `]` = `%5D`
  - `*` = `%2A`
  - `!` = `%21`
  - `@` = `%40`
  - `#` = `%23`
  - `$` = `%24`
  - `%` = `%25`
  - `&` = `%26`

### 5. **Network/Firewall Blocking**

Your network or firewall might be blocking the connection.

**Solution:**

- Try from a different network
- Check if your firewall allows outbound connections on port 5432
- Try using Supabase's connection pooler (port 6543) instead

### 6. **SSL/TLS Requirements**

Supabase requires SSL connections.

**Current connection string includes**: `?sslmode=require`

**If still failing, try:**

- `?sslmode=prefer` (allows non-SSL fallback)
- Or remove SSL requirement temporarily for testing

## Quick Test: Verify Connection String

1. **Get Connection String from Supabase:**

   - Dashboard → Settings → Database
   - Copy **"Connection string"** (URI format)

2. **Test with psql** (if installed):

   ```bash
   psql "postgresql://postgres.xxx:[PASSWORD]@db.xxx.supabase.co:5432/postgres"
   ```

3. **Or test with Prisma Studio:**

   ```bash
   npx prisma studio
   ```

## Alternative: Use Supabase Connection Pooler

For migrations, you might need to use the direct connection. But for testing, try the pooler:

**Pooled connection** (port 6543):

```text
postgresql://postgres.xxx:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true
```

**Direct connection** (port 5432):

```text
postgresql://postgres.xxx:[PASSWORD]@db.xxx.supabase.co:5432/postgres
```

## Next Steps

1. ✅ Check if database is paused in Supabase dashboard
2. ✅ Copy connection string directly from Supabase dashboard
3. ✅ Update `.env` file with correct connection string
4. ✅ Try `npx prisma migrate dev --name init` again

## If Still Failing

1. **Check Supabase Status**: <https://status.supabase.com>
2. **Contact Supabase Support**: If database should be accessible
3. **Try Alternative**: Use `prisma db push` instead of migrations (for development)

---

**Note**: Once connection is established, the migration will create:

- `User` table
- `Ride` table  
- `VibeType` enum
- `RideStatus` enum
- `_prisma_migrations` table (migration history)
