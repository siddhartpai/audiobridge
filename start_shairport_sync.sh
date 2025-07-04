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

sleep 50
# Connect JACK ports
jack_connect system:capture_1 system:playback_1
jack_connect system:capture_1 system:playback_2

# Start AirPlay
/usr/local/bin/shairport-sync -o jack
