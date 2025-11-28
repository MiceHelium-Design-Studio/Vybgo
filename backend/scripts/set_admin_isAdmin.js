const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, '..', 'prisma', 'dev.db');
const email = process.argv[2] || 'raghidhilal@gmail.com';

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

db.run('UPDATE "User" SET isAdmin = 1 WHERE email = ?', [email], function (err) {
  if (err) {
    console.error('Update error:', err.message);
    db.close();
    process.exit(1);
  }
  console.log('Rows updated:', this.changes);
  db.close();
});
