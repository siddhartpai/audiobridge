#!/bin/bash

# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"

# Check dependencies
if ! command -v jack_connect &>/dev/null; then
    echo "Error: jack_connect not found" >&2
    exit 1
fi

if ! command -v jack_lsp &>/dev/null; then
    echo "Error: jack_lsp not found" >&2
    exit 1
fi

# Wait for shairport-sync to register with JACK (max 30 seconds)
echo "Waiting for shairport-sync to register with JACK..."
for i in {1..30}; do
    if jack_lsp | grep -q "shairport-sync"; then
        echo "Shairport-sync ports found after $i seconds"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Warning: Shairport-sync ports not found after 30 seconds"
        echo "Available ports:"
        jack_lsp
        exit 1
    fi
    sleep 1
done

# Show available ports
echo "Available JACK ports:"
jack_lsp

# Connect Shairport to JACK
echo "Connecting shairport-sync to outputs..."
jack_connect shairport-sync:out_L system:playback_1 
jack_connect shairport-sync:out_R system:playback_2
echo "Shairport-sync connections established"
