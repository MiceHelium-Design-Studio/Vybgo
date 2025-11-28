const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const db = new sqlite3.Database('./prisma/dev.db', (err) => {
  if (err) {
    console.error('❌ Error opening database:', err.message);
    process.exit(1);
  }
});

async function createAdminUser() {
  const email = 'raghidhilal@gmail.com';
  const password = 'Oldschool1*';
  const name = 'Raghi Hilal';
  const id = crypto.randomUUID();

  try {
    // Hash the password
    const passwordHash = await bcrypt.hash(password, 10);
    
    console.log('🔧 Creating admin user in SQLite...');
    console.log(`📧 Email: ${email}`);
    console.log(`👤 Name: ${name}`);

    // Insert or update user
    db.run(
      `INSERT OR REPLACE INTO "User" (id, email, name, password, createdAt, updatedAt) 
       VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))`,
      [id, email, name, passwordHash],
      function(err) {
        if (err) {
          console.error('❌ Error inserting user:', err.message);
          process.exit(1);
        } else {
          console.log('✅ Admin user created successfully!\n');
          console.log('User Details:');
          console.log(`  ID: ${id}`);
          console.log(`  Email: ${email}`);
          console.log(`  Name: ${name}`);
          console.log(`\n🔑 Login Credentials:`);
          console.log(`  Email: ${email}`);
          console.log(`  Password: ${password}`);
          console.log(`\n✅ You can now log in to the app!`);
          
          db.close();
        }
      }
    );
  } catch (error) {
    console.error('❌ Error hashing password:', error.message);
    process.exit(1);
  }
}

createAdminUser();
