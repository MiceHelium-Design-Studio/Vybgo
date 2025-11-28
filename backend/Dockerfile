# Use Node.js 20 Alpine for smaller image size
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies needed for Prisma and native modules
RUN apk add --no-cache openssl libc6-compat

# Disable corepack and install Yarn 1.x (classic) for better Prisma compatibility
RUN corepack disable && npm install -g --force yarn@1.22.22

# Copy dependency manifests
COPY package.json yarn.lock* ./

# Install all dependencies (including dev deps for build)
# Use --frozen-lockfile if yarn.lock exists, otherwise regular install
RUN if [ -f yarn.lock ]; then \
      yarn install --frozen-lockfile && yarn cache clean; \
    else \
      yarn install && yarn cache clean; \
    fi

# Copy Prisma schema
COPY prisma ./prisma/

# Dummy DB URL so Prisma is happy during *build*
# (real DATABASE_URL comes from .env.production at runtime)
ENV DATABASE_URL="postgresql://user:password@localhost:5432/dummydb?schema=public"

# Generate Prisma Client
# Use npx to ensure Prisma binary is found correctly
RUN npx prisma generate

# Copy TypeScript config and source code
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript to JavaScript
RUN yarn build

# Optional: prune devDependencies to shrink image
# (Prisma Client is a runtime dependency, so it stays)
RUN if [ -f yarn.lock ]; then \
      yarn install --production --frozen-lockfile && yarn cache clean; \
    else \
      yarn install --production && yarn cache clean; \
    fi

# Expose port 3000
EXPOSE 3000

# Set NODE_ENV to production
ENV NODE_ENV=production

# Start the application
CMD ["node", "dist/index.js"]
