# Minimalist Ollama container based on PyTorch Dockerfile style
FROM debian:bullseye-slim

# Set necessary environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_ORIGINS="*" \
    PATH="/usr/local/bin:${PATH}" \
    OLLAMA_TIMEOUT=60

# Configure apt sources and install necessary dependencies
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    openssh-server \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Download and install Ollama
RUN mkdir -p /usr/local/bin && \
    wget -qO /usr/local/bin/ollama https://github.com/ollama/ollama/releases/download/v0.1.27/ollama-linux-amd64 && \
    chmod +x /usr/local/bin/ollama

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# Create necessary directories
RUN mkdir -p /app /root/.ollama /app/logs

# Set working directory
WORKDIR /app

# Copy startup scripts
COPY scripts/start.sh /app/
COPY scripts/model_init.sh /app/
RUN chmod +x /app/start.sh /app/model_init.sh

# Set container labels
LABEL maintainer="Sing" \
      description="Universal Ollama container for running various 7B language models" \
      usage="Set MODEL_NAME environment variable to specify model" \
      supported_models="codellama:7b, deepseek:7b, llama2:7b, qwen:7b" \
      github_repo="https://github.com/singaicloud/public-images"

# Expose SSH and Ollama ports
EXPOSE 22 11434

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ -z "$SSH_PASSWORD" ]; then\n\
  SSH_PASSWORD=${SSH_PASSWORD:-singaicloud}\n\
fi\n\
echo "root:$SSH_PASSWORD" | chpasswd\n\
/usr/sbin/sshd\n\
/app/start.sh\n\
tail -f /dev/null' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:11434/api/health || exit 1

# Set container startup command
CMD ["/app/entrypoint.sh"]