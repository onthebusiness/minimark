# syntax = docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-slim AS base

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y ca-certificates curl

# LABEL fly_launch_runtime="Node.js"

# Node.js app lives here
WORKDIR /app

# Install pnpm
RUN corepack enable
RUN pnpm --version


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build node modules
RUN apt-get install --no-install-recommends -y build-essential node-gyp pkg-config python-is-python3

ENV SKIP_WXT_PREPARE=1

# Install node modules
COPY --link . .
RUN pnpm install --frozen-lockfile
RUN pnpm --filter web... build
RUN rm -rf node_modules
RUN pnpm install --prod --frozen-lockfile


# Final stage for app image
FROM base

# Copy built application
COPY --from=build /app /app

# Set production environment
ENV NODE_ENV="production"
ENV PORT=3000

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 CMD curl --fail http://localhost:3000 || exit 1
CMD [ "pnpm", "--filter", "web", "start" ]