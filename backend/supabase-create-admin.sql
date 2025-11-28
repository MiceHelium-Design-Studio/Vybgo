-- SQL to insert admin user into Supabase PostgreSQL
-- Run this in Supabase SQL Editor after running supabase-schema.sql

INSERT INTO "User" (
  id, 
  email, 
  name, 
  "passwordHash", 
  "isAdmin",
  "createdAt", 
  "updatedAt"
) VALUES (
  'e3037b9e-4be4-458b-90fb-09cdcfb62b3b'::uuid,
  'raghidhilal@gmail.com',
  'Raghi Hilal',
  '$2a$10$7FE5.7Qb3rV8SqjI5/8nbe5RwG3A.7AQrQ8L5K3QV8X9L2O1O8zBa', -- Oldschool1* hashed
  true,
  NOW(),
  NOW()
) ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  "passwordHash" = EXCLUDED."passwordHash",
  "isAdmin" = COALESCE(EXCLUDED."isAdmin", "User"."isAdmin"),
  "updatedAt" = NOW();
