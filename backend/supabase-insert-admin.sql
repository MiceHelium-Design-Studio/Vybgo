-- Ready-to-run SQL to insert an admin user into the `users` table.
-- WARNING: Running this in production will create a user row outside Supabase Auth.
-- Prefer creating users via Supabase Auth and then setting is_admin = true.

-- Generated UUID and bcrypt hash for the admin user
-- id: 75bb7390-7f09-4e5e-8a56-6799795bebb9
-- password (plaintext): Oldschool1*  -- included here only for reference; do NOT store plaintext in production

INSERT INTO users (id, email, name, password_hash, is_admin, created_at)
VALUES (
  '75bb7390-7f09-4e5e-8a56-6799795bebb9',
  'raghidhilal@gmail.com',
  'Raghi Hilal',
  '$2a$12$stWS3IH6nbs83TbepwJx0uRCIwGLQAi6P2eb8eLFZwNdJwOkrf732',
  true,
  now()
);

-- Verification query:
-- SELECT id, email, is_admin, created_at FROM users WHERE email = 'raghidhilal@gmail.com';
