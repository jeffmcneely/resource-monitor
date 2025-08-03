# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create non-root user for security
RUN groupadd --gid 1000 resourcemonitor && \
    useradd --uid 1000 --gid resourcemonitor --shell /bin/bash --create-home resourcemonitor

# Install system dependencies for GPU monitoring (optional)
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY resource_monitor.py .

# Create directories for logs, data, and config
RUN mkdir -p /app/logs /app/data /etc/resourcemonitor && \
    chown -R resourcemonitor:resourcemonitor /app /etc/resourcemonitor

# Switch to non-root user
USER resourcemonitor

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import psutil; print('Health check passed')" || exit 1

# Default command
CMD ["python", "resource_monitor.py"]
