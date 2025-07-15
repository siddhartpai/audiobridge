#!/bin/bash

# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Check dependencies
if ! command -v jackd &>/dev/null; then
    echo "Error: jackd not found" >&2
    exit 1
fi

if ! command -v amixer &>/dev/null; then
    echo "Error: amixer not found" >&2
    exit 1
fi

sleep 10
ulimit -r 95  # Ensure high priority
ulimit -l unlimited  # Ensure memory locking

amixer -c 0 cset numid=8 0 # Unnecessary Capture Volume
amixer -c 0 cset numid=9 0 # Gain

# Start JACK with real-time priority
jackd -P95 -d alsa -d hw:0,0 -p 1024 -n 2 -r 44100
