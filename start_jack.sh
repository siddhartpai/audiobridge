#!/bin/bash

# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Check dependencies
for cmd in jackd amixer; do
    command -v "$cmd" >/dev/null || { echo "Error: $cmd not found" >&2; exit 1; }
done

# Wait for hardware to settle
sleep 2

# Set resource limits
ulimit -r unlimited   # Realtime priority
ulimit -l unlimited   # Locked memory

# Mixer configuration
amixer -c 0 cset numid=8 0  # Disable capture
amixer -c 0 cset numid=9 0  # Set gain to 0

# Start JACK with real-time priority
exec jackd -R -P95 -d alsa -d hw:0,0 -p 1024 -n 2 -r 44100
