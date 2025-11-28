const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');

// Load .env from backend root
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const dbPath = path.resolve(__dirname, '..', 'prisma', 'dev.db');
const email = process.argv[2] || 'raghidhilal@gmail.com';
const secret = process.env.JWT_SECRET;

if (!secret) {
  console.error('Missing JWT_SECRET in environment (.env)');
  process.exit(1);
}

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

db.get('SELECT id, email, name FROM "User" WHERE email = ?', [email], (err, row) => {
  if (err) {
    console.error('DB error:', err.message);
    db.close();
    process.exit(1);
  }

  if (!row) {
    console.error('User not found for email:', email);
    db.close();
    process.exit(2);
  }

  const token = jwt.sign({ userId: row.id }, secret, { expiresIn: '7d' });

  console.log(JSON.stringify({ user: row, token }));
  db.close();
});
