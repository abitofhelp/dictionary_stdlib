# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile — Dictionary REST Microservice (Production)
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
#
# Multi-stage build:
#   Stage 1 (builder) — compile the Ada project in release mode using the
#     Alire-managed GNAT toolchain from the dev container image.
#   Stage 2 (runtime) — copy the static binary into a minimal Ubuntu image
#     running as a nonroot user.
#
# The resulting image is small (~30 MB) and contains only:
#   - The dictionary binary
#   - curl (for health checks and debugging)
#   - A nonroot user (app:10000)
#
# Build:
#   docker build -t dictionary .
#
# Run:
#   docker run -p 8080:8080 dictionary
#
# Kubernetes liveness/readiness probe:
#   httpGet:
#     path: /health
#     port: 8080
#
# ============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Builder
# ---------------------------------------------------------------------------
# Use the dev container which has Alire, GNAT, and GPRbuild pre-installed.
# The toolchain symlinks are in /usr/local/bin, accessible to all users.
# ---------------------------------------------------------------------------
FROM ghcr.io/abitofhelp/dev-container-ada:latest AS builder

USER root
WORKDIR /build

# Copy project sources.  The .dockerignore excludes build artifacts.
COPY . .

# Fix ownership so the dev user can write build outputs.
RUN chown -R dev:dev /build

# Build as the dev user (Alire config lives under /home/dev).
USER dev

# Alire needs to resolve the toolchain on first build.  The release
# profile strips debug info and enables optimizations.
RUN cd /build \
 && alr build --release -- -j0

# ---------------------------------------------------------------------------
# Stage 2: Runtime
# ---------------------------------------------------------------------------
# Minimal Ubuntu matching the build base (glibc 2.35 compatibility).
# The dictionary binary depends only on libc — no GNAT runtime shared
# libraries are needed because GNAT statically links the Ada runtime.
# ---------------------------------------------------------------------------
FROM ubuntu:22.04

# Install curl for health-check probes and debugging.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Create a nonroot user.  UID 10000 is a common convention for
# unprivileged service accounts in containers and Kubernetes.
RUN groupadd --gid 10000 app \
 && useradd --uid 10000 --gid 10000 --no-create-home --shell /usr/sbin/nologin app

# Copy the release binary from the builder stage.
COPY --from=builder /build/bin/dictionary_stdlib /usr/local/bin/dictionary_stdlib
RUN chmod +x /usr/local/bin/dictionary_stdlib

# Run as nonroot.
USER app

# The service listens on port 8080.
EXPOSE 8080

# Health check for docker-compose and Swarm.
# Kubernetes uses its own httpGet probes instead.
HEALTHCHECK --interval=30s --timeout=3s --start-period=2s --retries=3 \
  CMD curl -sf http://localhost:8080/health || exit 1

ENTRYPOINT ["dictionary_stdlib"]
