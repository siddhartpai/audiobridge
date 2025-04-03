#!/bin/bash
#
exec >> /home/dietpi/audiobridge/logs/monitor.log 2>&1

# Threshold for detecting audio (adjust as needed)
THRESHOLD=-30 # in jack meter dB 

# Time without audio before turning off (in seconds)
TIMEOUT=$((10 * 60))

# Track last time audio was detected
LAST_ACTIVE=$(date +%s)

# Tasmota API
TASMOTA_IP="192.168.1.199"
TASMOTA_STATUS="http://$TASMOTA_IP/cm?cmnd=Power"
TASMOTA_ON="http://$TASMOTA_IP/cm?cmnd=Power%20ON"
TASMOTA_OFF="http://$TASMOTA_IP/cm?cmnd=Power%20OFF"

# Function to get the highest audio level from a port
get_audio_level() {
    local port=$1
    ( jack_meter "$port" -n 2>/dev/null & pid=$!; sleep 2; kill $pid ) | awk '
        { if ($1 == "-inf") print "-100"; else print $1; }
    ' | sort -n | tail -1
}

# Function to check the current power state of Tasmota
get_tasmota_status() {
    curl -s "$TASMOTA_STATUS" | grep -oE '"POWER":"(ON|OFF)"' | cut -d':' -f2 | tr -d '"'
}

while true; do
    # Get audio levels from both sources
    LEVEL1=$(get_audio_level system:capture_1)
    LEVEL2=$(get_audio_level shairport-sync:out_L)

    # Get the highest of the two
    HIGHEST_LEVEL=$(echo -e "$LEVEL1\n$LEVEL2" | sort -n | tail -1)

    # Get current Tasmota status
    DEVICE_STATUS=$(get_tasmota_status)

    # Check if audio is above the threshold
    if (( $(echo "$HIGHEST_LEVEL > $THRESHOLD" | bc -l) )); then
        LAST_ACTIVE=$(date +%s)
        if [ "$DEVICE_STATUS" == "OFF" ]; then
            echo "Audio detected ($HIGHEST_LEVEL dB), turning on Tasmota device..."
            curl -XGET "$TASMOTA_ON"
        fi
    else
        NOW=$(date +%s)
        if (( NOW - LAST_ACTIVE > TIMEOUT )); then
            if [ "$DEVICE_STATUS" == "ON" ]; then
                echo "No audio for 15 minutes, turning off Tasmota device..."
                curl -XGET "$TASMOTA_OFF"
            fi
        fi
    fi

    sleep 2
done

