#!/bin/bash


# Update system
apt-get update
apt-get upgrade -y

# Create swap file (important for t2.micro with 1GB RAM)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /home/ubuntu/strapi
cd /home/ubuntu/strapi

# Create docker-compose.yml with memory limits for t2.micro
cat > docker-compose.yml << 'EOL'
services:
  postgres:
    image: postgres:14-alpine
    container_name: strapi-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: strapi
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: ${db_password}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - strapi-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U strapi"]
      interval: 5s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 256M

  strapi:
    image: ${docker_image}
    container_name: strapi-app
    restart: unless-stopped
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: strapi
      DATABASE_USERNAME: strapi
      DATABASE_PASSWORD: ${db_password}
      NODE_ENV: production
      HOST: 0.0.0.0
      PORT: 1337
      NODE_OPTIONS: "--max-old-space-size=512"
    ports:
      - "80:1337"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - strapi-network
    volumes:
      - strapi-uploads:/opt/app/public/uploads
    deploy:
      resources:
        limits:
          memory: 512M

volumes:
  postgres-data:
  strapi-uploads:

networks:
  strapi-network:
    driver: bridge
EOL

# Start the application
docker-compose up -d

# Create a systemd service to ensure Docker Compose starts on boot
cat > /etc/systemd/system/strapi.service << 'EOL'
[Unit]
Description=Strapi Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/strapi
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL

# Enable the service
systemctl enable strapi.service