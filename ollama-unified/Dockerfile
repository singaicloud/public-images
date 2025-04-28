# Base image - using the official Ollama image
FROM ollama/ollama:latest

# Install SSH server for cross-node communication (similar to the pytorch-dist example)
RUN apt-get update && apt-get install -y openssh-server

# Configure SSH
RUN echo 'root:singaicloud' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd

# Create working directory
RUN mkdir -p /opt/ollama
WORKDIR /opt/ollama

# Add a startup script to initialize Ollama
COPY start-ollama.sh /opt/ollama/start-ollama.sh
RUN chmod +x /opt/ollama/start-ollama.sh

# Set permissions to allow non-root users in OpenShift-like environments
RUN chgrp -R 0 /opt/ollama \
    && chmod -R g+rwX /opt/ollama \
    && chgrp -R 0 /root/.ollama \
    && chmod -R g+rwX /root/.ollama

# Expose Ollama API port and SSH port
EXPOSE 11434 22

# Set the entrypoint to use our custom startup script
ENTRYPOINT ["/opt/ollama/start-ollama.sh"]
