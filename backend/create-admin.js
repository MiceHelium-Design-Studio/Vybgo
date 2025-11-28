const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

// Use SQLite schema for local development
process.env.PRISMA_SCHEMA_ENGINE_BINARY = './node_modules/@prisma/engines/schema-engine-windows.exe';

const prisma = new PrismaClient({
  errorFormat: 'pretty',
});

async function main() {
  const email = 'raghidhilal@gmail.com';
  const password = 'Oldschool1*';
  const name = 'Raghi Hilal';

  try {
    // Hash the password
    const passwordHash = await bcrypt.hash(password, 10);
    
    console.log('Creating admin user...');
    console.log(`Email: ${email}`);
    console.log(`Name: ${name}`);

    // Create the user
    const user = await prisma.user.upsert({
      where: { email },
      update: { passwordHash }, // Update password if user exists
      create: {
        id: require('crypto').randomUUID(),
        email,
        name,
        passwordHash,
      },
    });

    console.log('✅ Admin user created successfully!');
    console.log('\nUser Details:');
    console.log(`  ID: ${user.id}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Name: ${user.name}`);
    console.log(`  Password Hash: ${user.passwordHash.substring(0, 20)}...`);
    console.log('\n🔑 Login Credentials:');
    console.log(`  Email: ${email}`);
    console.log(`  Password: ${password}`);
    console.log('\n✅ User is ready to log in and test the app!');

  } catch (error) {
    console.error('❌ Error creating user:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
