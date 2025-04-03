#!/bin/bash
if ! timeout 5s jack_lsp &>/dev/null; then
    echo "JACK appears to be unresponsive. Restarting..."
    systemctl --user stop jackd
    sleep 2
    pkill -9 jackd  # Force kill if still running
    systemctl --user start jackd
fi

