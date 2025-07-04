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

sleep 60
jack_lsp
# Connect Shairport to JACK
jack_connect shairport-sync:out_L system:playback_1 
jack_connect shairport-sync:out_R system:playback_2
