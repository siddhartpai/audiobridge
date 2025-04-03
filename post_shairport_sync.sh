#!/bin/bash


sleep 60
jack_lsp
# Connect Shairport to JACK
jack_connect shairport-sync:out_L system:playback_1 
jack_connect shairport-sync:out_R system:playback_2
