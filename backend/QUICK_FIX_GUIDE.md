# 🚀 VYBGO Backend - Quick Fix Guide

## ⚡ IMMEDIATE ACTIONS REQUIRED

### 1. Update Your `.env` File

Add `DIRECT_URL` to your `.env` file:

```env
DATABASE_URL="postgresql://postgres:[ABCVYBGO123*!]@db.bkltwqmkajwhatnyzogs.supabase.co:5432/postgres?schema=public"
DIRECT_URL="postgresql://postgres:[ABCVYBGO123*!]@db.bkltwqmkajwhatnyzogs.supabase.co:5432/postgres?schema=public"
JWT_SECRET="3uM0ZoSG7mXpmDD3S8ESDyh64gKZdIeAurnDdKdcLxN1PlrsGpG0P6cEYLGjFKHT7Z6bAw7ECfDWuQA/hJsCBQ=="
PORT=3000
```

**Note**: For Supabase, both URLs are usually the same (direct connection on port 5432). If you're using connection pooling, `DATABASE_URL` might use port 6543 or have `?pgbouncer=true`.

### 2. Create Database Schema

Run this command to create all tables:

```bash
cd backend
npx prisma migrate dev --name init
```

This will:
- ✅ Create `prisma/migrations/` folder
- ✅ Generate migration files
- ✅ Create `User` and `Ride` tables in Supabase
- ✅ Create enums (`VibeType`, `RideStatus`)

### 3. Verify Tables Created

1. Open Supabase Dashboard
2. Go to **Table Editor**
3. You should see:
   - ✅ `User` table
   - ✅ `Ride` table
   - ✅ Enums in the schema

### 4. Test Locally

```bash
npm run dev
```

Then test registration:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'
```

### 5. Rebuild Docker Image

```bash
docker build -t vybgo-backend .
```

---

## 📋 What Was Fixed

✅ **Prisma Schema**: Added `directUrl` for Supabase compatibility  
✅ **Environment Config**: Added `DIRECT_URL` validation  
✅ **Documentation**: Updated `env.production.example` with clear instructions

---

## 🚨 If Migrations Fail

If `prisma migrate dev` fails, try:

```bash
# Alternative: Use db push (doesn't create migration files)
npx prisma db push

# Or check connection
npx prisma db pull
```

---

## 📖 Full Details

See `DIAGNOSTIC_REPORT.md` for complete analysis and deployment checklist.

