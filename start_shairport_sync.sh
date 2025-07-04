#!/bin/bash

# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"

# Check dependencies
if ! command -v jack_connect &>/dev/null; then
    echo "Error: jack_connect not found" >&2
    exit 1
fi

if ! command -v /usr/local/bin/shairport-sync &>/dev/null; then
    echo "Error: shairport-sync not found" >&2
    exit 1
fi

# Wait for JACK to be ready (max 30 seconds)
echo "Waiting for JACK to be ready..."
for i in {1..30}; do
    if jack_lsp &>/dev/null; then
        echo "JACK is ready after $i seconds"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Warning: JACK not ready after 30 seconds, proceeding anyway"
    fi
    sleep 1
done

# Connect JACK ports
echo "Connecting line-in to outputs..."
jack_connect system:capture_1 system:playback_1
jack_connect system:capture_1 system:playback_2

# Start AirPlay
echo "Starting shairport-sync..."
/usr/local/bin/shairport-sync -o jack
