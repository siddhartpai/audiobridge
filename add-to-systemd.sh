#!/bin/bash

# Configuration
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_DIR="/etc/systemd/system"

# Copy shairport-sync configuration to /etc
echo "Copying shairport-sync configuration..."
sudo cp "$BASE_DIR/etc/shairport-sync.conf" /etc/shairport-sync.conf
sudo cp "$BASE_DIR/etc/convolution_filter.wav" /etc/convolution_filter.wav

# Create systemd override for shairport-sync service
echo "Creating shairport-sync service override..."
sudo mkdir -p /etc/systemd/system/shairport-sync.service.d/
sudo cp "$BASE_DIR/systemd.confs/shairport-sync.service.override" /etc/systemd/system/shairport-sync.service.d/override.conf

# Update service files with current directory path (absolute) and copy to system
echo "Installing system services..."
for service in "$BASE_DIR"/systemd.confs/*.service; do
    # Skip the deprecated shairport.service - we use built-in shairport-sync.service instead
    if [[ $(basename "$service") == "shairport.service" ]]; then
        echo "Skipping deprecated shairport.service (using built-in shairport-sync.service)"
        continue
    fi
    sudo sed "s|/home/dietpi/audiobridge|$BASE_DIR|g" "$service" > /tmp/$(basename "$service")
    sudo mv /tmp/$(basename "$service") "$SERVICE_DIR/"
done

sudo cp "$BASE_DIR"/systemd.confs/*.timer "$SERVICE_DIR/"

sudo systemctl daemon-reload

# Enable services
sudo systemctl enable jackd.service
sudo systemctl enable post_jack.service
sudo systemctl enable shairport-sync.service  # Use built-in shairport-sync service
sudo systemctl enable post_shairport.service
sudo systemctl enable amp_control.service
sudo systemctl enable --now jack-healthcheck.timer

# Stop any running services first (clean slate)
echo "Stopping existing services..."
sudo systemctl stop amp_control.service 2>/dev/null || true
sudo systemctl stop post_shairport.service 2>/dev/null || true
sudo systemctl stop shairport-sync.service 2>/dev/null || true  # Use built-in service
sudo systemctl stop post_jack.service 2>/dev/null || true
sudo systemctl stop jackd.service 2>/dev/null || true

# Start services (non-blocking)
echo "Starting services..."
sudo systemctl start jackd.service --no-block
sleep 2
sudo systemctl start post_jack.service --no-block
sleep 2
sudo systemctl start shairport-sync.service --no-block  # Use built-in service
sleep 2
sudo systemctl start post_shairport.service --no-block
sleep 2
sudo systemctl start amp_control.service --no-block

echo "Installation complete!"
echo ""
echo "Services configured:"
echo "  - jackd.service (JACK audio daemon)"
echo "  - post_jack.service (JACK line-in connections)"
echo "  - shairport-sync.service (built-in AirPlay receiver with JACK backend)"
echo "  - post_shairport.service (JACK AirPlay connections)"
echo "  - amp_control.service (audio monitoring & amplifier control)"
echo "  - jack-healthcheck.timer (health monitoring)"
echo ""
echo "Check service status with: sudo systemctl status <service-name>"
echo "View logs with: sudo journalctl -u <service-name> -f"
echo ""
echo "Note: shairport-sync now uses the built-in systemd service with JACK backend"
echo "Configuration: /etc/shairport-sync.conf"

exit 0

