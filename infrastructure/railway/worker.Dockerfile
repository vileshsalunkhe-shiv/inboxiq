# Multi-stage build for worker service
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --user -r requirements.txt

# Production stage
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/home/worker/.local/bin:$PATH

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 worker && \
    mkdir -p /app && \
    chown -R worker:worker /app

# Copy Python dependencies from builder
COPY --from=builder --chown=worker:worker /root/.local /home/worker/.local

# Switch to non-root user
USER worker
WORKDIR /app

# Copy application code
COPY --chown=worker:worker backend/ .

# Worker doesn't need to expose ports

# Graceful shutdown handling
STOPSIGNAL SIGTERM

# Run worker with proper signal handling
CMD ["python", "worker.py"]
