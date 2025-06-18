FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install git and other dependencies
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone the remarkable-update repository
RUN git clone https://github.com/ddvk/remarkable-update.git .

# Create updates directory for firmware files
RUN mkdir -p /app/updates

# Expose the port that the server runs on
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Create a script to run the server with proper hostname detection
RUN echo '#!/bin/bash\n\
if [ -z "$HOST_IP" ]; then\n\
    echo "HOST_IP environment variable not set. Using default behavior."\n\
    python3 serve.py\n\
else\n\
    echo "Using HOST_IP: $HOST_IP"\n\
    python3 serve.py "$HOST_IP"\n\
fi' > /app/start_server.sh && \
    chmod +x /app/start_server.sh

# Default command
CMD ["/app/start_server.sh"]
