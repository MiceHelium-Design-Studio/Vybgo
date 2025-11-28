const { readFile } = require('fs').promises;
const path = require('path');
const { Client } = require('pg');

async function run() {
  const dbUrl = process.env.SUPABASE_DB_URL || process.argv[2];
  if (!dbUrl) {
    console.error('ERROR: SUPABASE_DB_URL env var or first arg required.');
    process.exit(2);
  }

  const files = [
    'supabase-schema.sql',
    'RLS_POLICIES_COMPREHENSIVE.sql',
    'supabase-create-admin.sql',
    'supabase-insert-admin.sql'
  ];

  // Allow forcing a specific host (useful when DNS returns IPv6-only records)
  const forcedHost = process.env.SUPABASE_FORCE_IPV4_HOST;
  const insecureSsl = (process.env.SUPABASE_INSECURE_SSL || '').toLowerCase() === 'true';

  let clientConfig = { connectionString: dbUrl };
  if (forcedHost) {
    // Replace hostname in connection string with the forced IP, keep credentials/db
    try {
      const url = new URL(dbUrl);
      url.hostname = forcedHost;
      clientConfig = { connectionString: url.toString() };
    } catch (e) {
      console.warn('Could not parse DB URL to force host:', e.message);
    }
  }
  if (insecureSsl) {
    clientConfig.ssl = { rejectUnauthorized: false };
  }

  const client = new Client(clientConfig);
  try {
    console.log('Connecting to database...');
    await client.connect();

    for (const f of files) {
      const p = path.join(__dirname, f);
      console.log(`\n--- Applying ${f} ---`);
      const sql = await readFile(p, 'utf8');
      try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('COMMIT');
        console.log(`Applied ${f}`);
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(`Error applying ${f}:`, err.message || err);
        throw err;
      }
    }

    console.log('\nVerifying admin user...');
    const res = await client.query(`SELECT id, email, is_admin, created_at FROM users WHERE email = $1 LIMIT 1`, ['raghidhilal@gmail.com']);
    if (res.rows.length === 0) {
      console.log('No admin user found with that email.');
    } else {
      console.log('Admin row:', res.rows[0]);
    }
  } finally {
    await client.end();
    console.log('Disconnected.');
  }
}

run().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
