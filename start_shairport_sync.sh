#!/bin/bash

sleep 50
# Connect JACK ports
jack_connect system:capture_1 system:playback_1
jack_connect system:capture_1 system:playback_2

# Start AirPlay
nice -n 10 /usr/local/bin/shairport-sync -o jack

#sleep 10
#jack_lsp
## Connect Shairport to JACK
#jack_connect shairport-sync:out_L system:playback_1
#jack_connect shairport-sync:out_R system:playback_2
