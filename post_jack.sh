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

# Wait for JACK to be ready (max 30 seconds)
echo "Waiting for JACK to be ready..."
for i in {1..30}; do
    if jack_lsp | grep -q "system:capture_1"; then
        echo "JACK system ports found after $i seconds"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Warning: JACK system ports not found after 30 seconds"
        echo "Available ports:"
        jack_lsp
        exit 1
    fi
    sleep 1
done

# Show available ports
echo "Available JACK ports:"
jack_lsp

# Connect line-in (microphone) to both playback channels
echo "Connecting line-in to outputs..."
jack_connect system:capture_1 system:playback_1
jack_connect system:capture_1 system:playback_2
echo "Line-in connections established"