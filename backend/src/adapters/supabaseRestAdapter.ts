/**
 * Supabase REST API Adapter
 * 
 * This adapter bypasses the IPv6-only PostgreSQL connection issue by using
 * Supabase's PostgREST HTTP API instead of direct psql connection.
 * 
 * Usage: When direct psql connection fails due to network issues,
 * use this adapter to connect via HTTPS instead.
 */

import { createClient } from '@supabase/supabase-js';

// Extract Supabase credentials from DATABASE_URL
function parseSupabaseCredentials() {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    throw new Error('DATABASE_URL not set');
  }

  // Format: postgresql://user:password@host:port/database?params
  const urlMatch = dbUrl.match(
    /postgresql:\/\/([^:]+):([^@]+)@([^:]+):(\d+)\/(.+)\?/
  );

  if (!urlMatch) {
    throw new Error('Invalid DATABASE_URL format');
  }

  const [, user, password, host, port, database] = urlMatch;

  // Extract project reference from host
  // Format: db.bkltwqmkajwhatnyzogs.supabase.co
  const projectMatch = host.match(/db\.([a-z0-9]+)\.supabase\.co/);
  if (!projectMatch) {
    throw new Error('Could not extract Supabase project reference from host');
  }

  const projectRef = projectMatch[1];

  return {
    projectRef,
    user,
    password: decodeURIComponent(password),
    database,
  };
}

// Initialize Supabase REST client
function initializeSupabaseClient() {
  const { projectRef } = parseSupabaseCredentials();

  const supabaseUrl = `https://${projectRef}.supabase.co`;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!serviceRoleKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY not set in .env');
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  return client;
}

// Test connection
export async function testConnection() {
  try {
    console.log('🔍 Testing Supabase REST API connection...');
    const client = initializeSupabaseClient();
    
    const { data, error } = await client
      .from('User')
      .select('id')
      .limit(1);

    if (error) {
      throw error;
    }

    console.log('✅ Supabase REST API connection successful!');
    console.log(`   Found ${data?.length || 0} users in database`);
    return true;
  } catch (error) {
    console.error('❌ Supabase REST API connection failed:');
    console.error(error instanceof Error ? error.message : error);
    return false;
  }
}

// Example: Get user by email
export async function getUserByEmail(email: string) {
  const client = initializeSupabaseClient();
  const { data, error } = await client
    .from('users')
    .select('*')
    .eq('email', email)
    .single();

  if (error) {
    console.error('Error fetching user:', error);
    throw error;
  }

  return data;
}

// Example: Create user
export async function createUserRest(userData: {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
}) {
  const client = initializeSupabaseClient();
  const { data, error } = await client
    .from('users')
    .insert([userData]);

  if (error) {
    console.error('Error creating user:', error);
    throw error;
  }

  return data;
}

// Example: Update user
export async function updateUserRest(
  id: string,
  updates: Record<string, any>
) {
  const client = initializeSupabaseClient();
  const { data, error } = await client
    .from('users')
    .update(updates)
    .eq('id', id);

  if (error) {
    console.error('Error updating user:', error);
    throw error;
  }

  return data;
}

// Example: Get all rides for user
export async function getUserRidesRest(userId: string) {
  const client = initializeSupabaseClient();
  const { data, error } = await client
    .from('rides')
    .select('*')
    .eq('user_id', userId);

  if (error) {
    console.error('Error fetching rides:', error);
    throw error;
  }

  return data;
}

// Run test if executed directly
if (require.main === module) {
  testConnection().then((success) => {
    process.exit(success ? 0 : 1);
  });
}

export default {
  testConnection,
  getUserByEmail,
  createUserRest,
  updateUserRest,
  getUserRidesRest,
};
