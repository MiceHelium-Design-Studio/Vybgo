Supabase deployment instructions
===============================

Purpose
-------
This file explains the exact steps to apply the production SQL schema and Row-Level Security (RLS) policies to your Supabase project using the SQL editor. It assumes you have two SQL files in this repository:

- `supabase-schema.sql` — the DDL for tables/indexes/constraints matching the Postgres schema.
- `RLS_POLICIES_COMPREHENSIVE.sql` — the RLS policies and helper functions to harden access.

Pre-flight checklist
-------------------

- Have Supabase project access and rights to run SQL (SQL Editor or psql with service role key).
- Back up any existing database or take a snapshot (recommended) before running DDL that modifies schema.
- Keep a copy of your current `.env` values (especially `SUPABASE_SERVICE_ROLE_KEY`).

Step 1 — Open Supabase SQL Editor
---------------------------------

1. Sign in to the Supabase dashboard and open your project.
2. Open `SQL` -> `Editor`.

Step 2 — Apply schema DDL
--------------------------

1. In the SQL editor, open the `supabase-schema.sql` file from this repository (copy/paste its contents into the editor).
2. Run it. This creates the tables, indices, and columns expected by the backend.

Step 3 — Apply RLS policies
---------------------------

1. After the schema is in place, open `RLS_POLICIES_COMPREHENSIVE.sql` and run it in the SQL editor.
2. This file defines RLS policies, roles, and helper functions the app expects.

Notes about order: apply schema first, then policies. If policies reference functions or types defined in the schema, running them first avoids errors.

Step 4 — Update environment variables
------------------------------------

1. In your deployment environment (server or hosting), update `DATABASE_URL` and `DIRECT_URL` to point at the Supabase Postgres connection string.
2. Add `SUPABASE_SERVICE_ROLE_KEY` (service role key) to environment variables for any server-side code that needs elevated access (be careful — never ship this to client-side code).

Step 5 — Create admin user (if needed)
-------------------------------------

If you need to create the owner/admin account (email: `raghidhilal@gmail.com`) manually in production:

1. Use the SQL editor or Supabase Auth to create the user record, or run an `INSERT` into the `users` table. Example (do not store plaintext passwords):

   -- Example: create a record with a hashed password generated server-side
   INSERT INTO "User" (id, email, password, name, "isAdmin", "createdAt", "updatedAt")
   VALUES (
     gen_random_uuid(),
     'raghidhilal@gmail.com',
     '<bcrypt-hash-generated-on-server>',
     'Raghi Hilal',
     true,
     NOW(), NOW()
   );

2. Alternatively, use the backend script `scripts/create-admin-sqlite.js` as reference to generate a hashed password, then adapt that to a one-off SQL `INSERT` using the hashed value.

Step 6 — Verify connectivity from backend
----------------------------------------

From your backend server (or CI), verify connections and simple queries:

1. Verify basic connection: run a small query via psql or via your server logs.

2. Test an authenticated server-side call using the service role key (example using curl to Supabase REST endpoint):

   curl -X GET 'https://<your-project>.supabase.co/rest/v1/User?select=*&limit=1' \
     -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
     -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

   The call should return rows if the service role key is valid.

Step 7 — Test application flows
-------------------------------

- Start the backend pointing to the Supabase Postgres database. Ensure `DATABASE_URL` and `DIRECT_URL` are correct.
- Hit `/api/auth/login` and `/api/auth/whoami` from the app or `curl` using credentials you created for the admin user.

Rollback plan
-------------

- If anything goes wrong, restore from backup/snapshot and review the SQL error logs in the Supabase SQL editor.

Security reminders
------------------

- Never expose `SUPABASE_SERVICE_ROLE_KEY` to client-side code.
- Use least-privilege keys for client operations (anon/public key) and reserve the service role key for server operations only.

Files referenced
----------------

- `supabase-schema.sql` (run first)
- `RLS_POLICIES_COMPREHENSIVE.sql` (run second)
- `scripts/create-admin-sqlite.js` (reference for password hashing)

If you want, I can:

- Run a dry-run checklist and validate the SQL files for obvious errors.
- Provide the exact SQL `INSERT` statements to create the admin user using a bcrypt hash I can generate for you (I will not store the plaintext password).
