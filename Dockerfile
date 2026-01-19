ARG BASE_IMAGE="nvcr.io/nvidia/cuda"
ARG BASE_IMAGE_TAG="12.4.1-runtime-ubuntu22.04"

# --- Builder stage: install dependencies and build venv ---
FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS builder

# Install uv (fast Python package manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app/moshi/

# Copy source and dependency files for build
COPY moshi/ /app/moshi/

# Create venv and install dependencies
RUN uv venv /app/moshi/.venv --python 3.12 \
    && uv sync \
    && rm -rf /root/.cache /root/.local

# --- Final stage: minimal runtime image ---
FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS final

WORKDIR /app/moshi/

# Copy venv and source from builder
COPY --from=builder /app/moshi/.venv /app/moshi/.venv
COPY --from=builder /app/moshi /app/moshi

# Create SSL directory (if needed at runtime)
RUN mkdir -p /app/ssl

# Use a non-root user for security (optional, comment out if CUDA needs root)
# RUN useradd -m moshiuser && chown -R moshiuser /app
# USER moshiuser

EXPOSE 8998

ENTRYPOINT ["/app/moshi/.venv/bin/python", "-m", "moshi.server", "--ssl", "/app/ssl"]