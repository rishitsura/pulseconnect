# ────────────────────────────────────────────────
# PulseNet Frontend — Dockerfile (React + Vite)
# Multi-stage: builder → Nginx runtime
# ────────────────────────────────────────────────

# ── Stage 1: Build the Vite app ───────────────
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --prefer-offline

COPY . .

ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ── Stage 2: Serve with Nginx ─────────────────
FROM nginx:1.25-alpine AS runner

LABEL maintainer="PulseNet Team"
LABEL description="PulseNet React+Vite frontend via Nginx"

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx config (handles SPA routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
