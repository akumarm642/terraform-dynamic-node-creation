#!/bin/bash
set -e

############################################################
# Get EC2 Private IP using IMDSv2 (REQUIRED in AWS)
############################################################
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Detected EC2 Public IP: $PUBLIC_IP"

############################################################
# Update system
############################################################
apt update -y

############################################################
# Install Docker
############################################################
apt install -y docker.io curl
systemctl enable docker

############################################################
# Configure Docker to enable LOCAL TCP (2375) safely
############################################################

# Docker daemon config
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOT
{
  "hosts": [
    "unix:///var/run/docker.sock",
    "tcp://127.0.0.1:2375"
  ]
}
EOT

# systemd override to remove "-H fd://"
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf <<EOT
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOT

# Reload systemd and start Docker
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart docker

############################################################
# Add ubuntu user to docker group
############################################################
usermod -aG docker ubuntu

############################################################
# Install Docker Compose plugin
############################################################
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

############################################################
# Prepare working directory
############################################################
mkdir -p /home/ubuntu/selenium/assets
cd /home/ubuntu/selenium

############################################################
# config01.toml
############################################################
cat > config01.toml <<EOT
[docker]
configs = [
  "selenium/standalone-firefox:4.35.0-20250909", "{\\"browserName\\": \\"firefox\\", \\"platformName\\": \\"linux\\"}",
  "selenium/standalone-chrome:4.35.0-20250909", "{\\"browserName\\": \\"chrome\\", \\"platformName\\": \\"linux\\"}",
  "selenium/standalone-edge:4.35.0-20250909", "{\\"browserName\\": \\"MicrosoftEdge\\", \\"platformName\\": \\"linux\\"}"
]

host-config-keys = ["Dns", "DnsOptions", "DnsSearch", "ExtraHosts", "Binds"]
url = "http://127.0.0.1:2375"
video-image = "selenium/video:ffmpeg-6.1-20240224"

[server]
host = "$PUBLIC_IP"
port = 6666

[node]
max-sessions = 2
EOT

############################################################
# config02.toml
############################################################
cat > config02.toml <<EOT
[docker]
configs = [
  "selenium/standalone-firefox:4.35.0-20250909", "{\\"browserName\\": \\"firefox\\", \\"platformName\\": \\"linux\\"}",
  "selenium/standalone-chrome:4.35.0-20250909", "{\\"browserName\\": \\"chrome\\", \\"platformName\\": \\"linux\\"}",
  "selenium/standalone-edge:4.35.0-20250909", "{\\"browserName\\": \\"MicrosoftEdge\\", \\"platformName\\": \\"linux\\"}"
]

host-config-keys = ["Dns", "DnsOptions", "DnsSearch", "ExtraHosts", "Binds"]
url = "http://127.0.0.1:2375"
video-image = "selenium/video:ffmpeg-6.1-20240224"

[server]
host = "$PUBLIC_IP"
port = 7777

[node]
max-sessions = 2
EOT

############################################################
# docker-compose.yml
############################################################
cat > docker-compose.yml <<'EOT'
services:
  node-docker1:
    image: selenium/node-docker:4.38.0-20251101
    network_mode: host
    volumes:
      - ./assets:/opt/selenium/assets
      - ./config01.toml:/opt/selenium/docker.toml
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SE_NODE_DOCKER_CONFIG_FILENAME=docker.toml
      - SE_VNC_NO_PASSWORD=1
      - SE_EVENT_BUS_HOST=103.152.114.177
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=6

  node-docker2:
    image: selenium/node-docker:4.38.0-20251101
    network_mode: host
    volumes:
      - ./assets:/opt/selenium/assets
      - ./config02.toml:/opt/selenium/docker.toml
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SE_NODE_DOCKER_CONFIG_FILENAME=docker.toml
      - SE_SESSION_TIMEOUT=100
      - SE_NEW_SESSION_WAIT_TIMEOUT=600
      - SE_VNC_NO_PASSWORD=1
      - SE_EVENT_BUS_HOST=103.152.114.177
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=7
EOT

############################################################
# Fix permissions
############################################################
chown -R ubuntu:ubuntu /home/ubuntu/selenium

############################################################
# Start Selenium Node containers
############################################################
su - ubuntu -c "cd /home/ubuntu/selenium && docker compose up -d"

echo "Selenium Node setup completed successfully"

