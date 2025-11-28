import dotenv from 'dotenv';

// Load environment variables. Use a dedicated `.env.development` file when
// running in development so we can point to a local SQLite DB without
// overwriting production `.env` values.
const envFile = process.env.NODE_ENV === 'development' ? '.env.development' : '.env';
dotenv.config({ path: envFile });

// Validate required environment variables
const requiredEnvVars = {
  JWT_SECRET: process.env.JWT_SECRET,
};

// DATABASE_URL is optional (can use REST API instead)
// DIRECT_URL is optional (falls back to DATABASE_URL)

// Check for missing required variables
const missingVars = Object.entries(requiredEnvVars)
  .filter(([_, value]) => !value)
  .map(([key]) => key);

if (missingVars.length > 0) {
  console.error('❌ Missing required environment variables:');
  missingVars.forEach((varName) => {
    console.error(`   - ${varName}`);
  });
  console.error('\nPlease set these variables in your .env file.');
  process.exit(1);
}

// Export typed environment configuration
export const env = {
  port: Number(process.env.PORT) || 3000,
  databaseUrl: process.env.DATABASE_URL || '',
  directUrl: process.env.DIRECT_URL,
  jwtSecret: process.env.JWT_SECRET!,
  fcmServerApiKey: process.env.FCM_SERVER_API_KEY, // Optional for FCM push notifications
};


