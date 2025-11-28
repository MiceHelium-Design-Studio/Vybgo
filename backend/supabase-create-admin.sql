-- SQL to insert admin user into Supabase PostgreSQL
-- Run this in Supabase SQL Editor after running supabase-schema.sql

INSERT INTO users (
  id,
  email,
  name,
  password_hash,
  is_admin,
  created_at,
  updated_at
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
  password_hash = EXCLUDED.password_hash,
  is_admin = COALESCE(EXCLUDED.is_admin, users.is_admin),
  updated_at = NOW();
