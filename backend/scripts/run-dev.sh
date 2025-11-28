#!/bin/bash
# Script to run the VYBGO backend in development mode with SQLite

set -e  # Exit on any command failure

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"

# Change to backend directory
cd "$BACKEND_DIR"

echo "📦 Setting up VYBGO backend for development..."

# Check if SQLite schema exists
if [ ! -f prisma/schema.sqlite.prisma ]; then
    echo "❌ Error: prisma/schema.sqlite.prisma not found"
    exit 1
fi

# Check if current schema uses PostgreSQL (only backup if so)
if grep -q 'provider = "postgresql"' prisma/schema.prisma 2>/dev/null; then
    if [ ! -f prisma/schema.prisma.postgres.bak ]; then
        cp prisma/schema.prisma prisma/schema.prisma.postgres.bak
        echo "📋 Backed up PostgreSQL schema"
    fi
fi

# Use SQLite schema
cp prisma/schema.sqlite.prisma prisma/schema.prisma
echo "✅ Using SQLite schema for development"

# Generate Prisma client
echo "🔧 Generating Prisma client..."
npm run prisma:generate

# Create absolute path for database URL
DB_PATH="$BACKEND_DIR/prisma/dev.db"
export DATABASE_URL="file:$DB_PATH"
export DIRECT_URL="file:$DB_PATH"
export NODE_ENV=development

echo "📂 Database path: $DB_PATH"
echo "🚀 Starting development server (port defined in .env.development)..."

# Start the server
npm run dev
