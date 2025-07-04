#!/bin/bash

# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"

# Check dependencies
if ! command -v jack_lsp &>/dev/null; then
    echo "Error: jack_lsp not found" >&2
    exit 1
fi

if ! command -v systemctl &>/dev/null; then
    echo "Error: systemctl not found" >&2
    exit 1
fi

if ! timeout 5s jack_lsp &>/dev/null; then
    echo "JACK appears to be unresponsive. Restarting..."
    systemctl --user stop jackd
    sleep 2
    pkill -9 jackd  # Force kill if still running
    systemctl --user start jackd
fi

