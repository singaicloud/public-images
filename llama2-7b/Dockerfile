# Phase 1: Build base environment
FROM debian:bullseye-slim as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Configure Aliyun apt source for faster downloads
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# Install necessary build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Download and install Ollama (with retry mechanism)
RUN mkdir -p /usr/local/bin && \
    for i in $(seq 1 3); do \
        (wget -qO /usr/local/bin/ollama https://github.com/ollama/ollama/releases/download/v0.1.27/ollama-linux-amd64 && \
        chmod +x /usr/local/bin/ollama && break) || \
        if [ $i -lt 3 ]; then sleep 15; else exit 1; fi; \
    done

# Phase 2: Final image
FROM debian:bullseye-slim

# Set model name and version
ENV MODEL_NAME=llama2:7b \
    MODEL_VERSION=1.0 \
    DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_ORIGINS="*" \
    OLLAMA_USERNAME="admin" \
    PATH="/usr/local/bin:${PATH}" \
    OLLAMA_TIMEOUT=120

# Configure apt sources
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# Install minimum runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openssh-server \
    socat \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Copy Ollama from builder stage
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/

# Create necessary directories
RUN mkdir -p /usr/local/lib/ollama && \
    mkdir -p /app /root/.ollama /app/logs /var/run/sshd

# Configure SSH
RUN echo 'root:PASSWORD' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set labels
LABEL maintainer="Sing" \
      model="llama2-7b" \
      version="1.0" \
      description="General-purpose conversational model designed for dialogue applications and text generation" \
      vendor="Meta" \
      applicable_scenarios="✓ text generation ✓ conversation ✓ content creation" \
      recommended_configuration="RTX 3090, 24GB VRAM" \
      default_port="22,11434" \
      default_entrypoint="/usr/sbin/sshd && /usr/local/bin/ollama serve" \
      github_repo="https://github.com/singaicloud/public-images/tree/main/llama2-7b"

# Set working directory
WORKDIR /app

# Expose SSH, Ollama and forwarding ports
EXPOSE 22
EXPOSE 8080
EXPOSE 11434

# Add initialization and startup scripts
COPY scripts/model_init.sh /app/
COPY start.sh /app/
RUN chmod +x /app/model_init.sh /app/start.sh

# Create entrypoint script
RUN echo '#!/bin/bash\n\
/usr/sbin/sshd\n\
/app/start.sh\n\
tail -f /dev/null' > /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh

# Initialize model
RUN /app/model_init.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:11434/api/health || exit 1

# Set container startup command
CMD ["/app/entrypoint.sh"]
