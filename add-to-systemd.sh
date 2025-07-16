#!/bin/bash

# Configuration
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_DIR="~/.config/systemd/user"

# Ensure systemd user directory exists
mkdir -p ~/.config/systemd/user

# Copy shairport-sync configuration to /etc
echo "Copying shairport-sync configuration..."
sudo cp "$BASE_DIR/etc/shairport-sync.conf" /etc/shairport-sync.conf
sudo cp "$BASE_DIR/etc/convolution_filter.wav" /etc/convolution_filter.wav

# Update service files with current directory path (absolute)
for service in "$BASE_DIR"/systemd.confs/*.service; do
    sed "s|/home/dietpi/audiobridge|$BASE_DIR|g" "$service" > ~/.config/systemd/user/$(basename "$service")
done

cp "$BASE_DIR"/systemd.confs/*.timer ~/.config/systemd/user/

systemctl --user daemon-reload

# Enable services
systemctl --user enable jackd.service
systemctl --user enable shairport.service
systemctl --user enable post_shairport.service
systemctl --user enable amp_control.service
systemctl --user enable --now jack-healthcheck.timer

# Stop any running services first (clean slate)
echo "Stopping existing services..."
systemctl --user stop amp_control.service 2>/dev/null || true
systemctl --user stop post_shairport.service 2>/dev/null || true
systemctl --user stop shairport.service 2>/dev/null || true
systemctl --user stop jackd.service 2>/dev/null || true

# Start services (non-blocking)
echo "Starting services..."
systemctl --user start jackd.service --no-block
sleep 2
systemctl --user start shairport.service --no-block
sleep 2
systemctl --user start post_shairport.service --no-block
sleep 2
systemctl --user start amp_control.service --no-block

echo "Installation complete!"
echo "Check service status with: systemctl --user status <service-name>"
echo "View logs with: journalctl --user -u <service-name> -f"

exit 0

