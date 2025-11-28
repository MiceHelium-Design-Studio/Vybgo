const { readFile } = require('fs').promises;
const path = require('path');
const https = require('https');

async function executeSQL(projectRef, serviceRoleKey, sql) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ query: sql });
    
    const options = {
      hostname: `${projectRef}.supabase.co`,
      port: 443,
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length,
        'apikey': serviceRoleKey,
        'Authorization': `Bearer ${serviceRoleKey}`
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, body });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function run() {
  const projectRef = process.env.SUPABASE_PROJECT_REF || 'bkltwqmkajwhatnyzogs';
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.argv[2];
  
  if (!serviceRoleKey) {
    console.error('ERROR: SUPABASE_SERVICE_ROLE_KEY env var or first arg required.');
    process.exit(2);
  }

  const files = [
    'supabase-schema.sql',
    'RLS_POLICIES_COMPREHENSIVE.sql',
    'supabase-insert-admin.sql'
  ];

  console.log(`Connecting to Supabase project: ${projectRef}`);

  for (const f of files) {
    const p = path.join(__dirname, f);
    console.log(`\n--- Applying ${f} ---`);
    try {
      const sql = await readFile(p, 'utf8');
      
      // Split on semicolons and execute each statement
      const statements = sql
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0 && !s.startsWith('--'));
      
      for (const stmt of statements) {
        if (stmt) {
          console.log(`Executing: ${stmt.substring(0, 80)}...`);
          await executeSQL(projectRef, serviceRoleKey, stmt);
        }
      }
      
      console.log(`✓ Applied ${f}`);
    } catch (err) {
      console.error(`✗ Error applying ${f}:`, err.message || err);
      // Continue with next file
    }
  }

  console.log('\n--- Verification (manual check required) ---');
  console.log('Please verify in Supabase Dashboard > Table Editor:');
  console.log('SELECT id, email, is_admin FROM users WHERE email = \'raghidhilal@gmail.com\';');
}

run().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
