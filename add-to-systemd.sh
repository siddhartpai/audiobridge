#!/bin/bash

# Configuration
BASE_DIR="$(dirname "$0")"
SERVICE_DIR="~/.config/systemd/user"

# Ensure systemd user directory exists
mkdir -p ~/.config/systemd/user

# Update service files with current directory path
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

# Start services
systemctl --user start jackd.service
systemctl --user start shairport.service
systemctl --user start post_shairport.service
systemctl --user start amp_control.service

