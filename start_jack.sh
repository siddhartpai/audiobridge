#!/bin/bash

sleep 10
ulimit -r 95  # Ensure high priority
ulimit -l unlimited  # Ensure memory locking

amixer -c 0 cset numid=8 0 # Unnecessary Capture Volume
amixer -c 0 cset numid=9 0 # Gain

# Start JACK with real-time priority
jackd -P95 -d alsa -d hw:0,0 -p 512 -n 3 -r 44100
