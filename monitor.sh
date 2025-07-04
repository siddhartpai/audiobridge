#!/bin/bash
#
# Configuration
BASE_DIR="${BASE_DIR:-$(dirname "$0")}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

exec >> "$LOG_DIR/monitor.log" 2>&1

# Threshold for detecting audio (adjust as needed)
THRESHOLD=-35 # in jack meter dB 

# Time without audio before turning off (in seconds)
TIMEOUT=$((10 * 60))

# Track last time audio was detected
LAST_ACTIVE=$(date +%s)

# Tasmota API
TASMOTA_IP="${TASMOTA_IP:-192.168.1.199}"
TASMOTA_STATUS="http://$TASMOTA_IP/cm?cmnd=Power"
TASMOTA_ON="http://$TASMOTA_IP/cm?cmnd=Power%20ON"
TASMOTA_OFF="http://$TASMOTA_IP/cm?cmnd=Power%20OFF"

# Check dependencies
check_dependencies() {
    local missing=()
    for cmd in jack_meter bc curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing dependencies: ${missing[*]}" >&2
        exit 1
    fi
}

# Check dependencies on startup
check_dependencies

# Function to get the highest audio level from a port
get_audio_level() {
    local port=$1
    local level
    
    # Check if port exists
    if ! jack_lsp | grep -q "^$port$"; then
        echo "-100"
        return
    fi
    
    level=$(timeout 5s jack_meter "$port" -n 2>/dev/null | head -1 | awk '
        { if ($1 == "-inf" || $1 == "") print "-100"; else print $1; }
    ')
    
    # Validate numeric output
    if [[ ! "$level" =~ ^-?[0-9]+(\.?[0-9]*)?$ ]]; then
        echo "-100"
    else
        echo "$level"
    fi
}

# Function to check the current power state of Tasmota
get_tasmota_status() {
    local status
    status=$(curl -s --connect-timeout 5 --max-time 10 "$TASMOTA_STATUS" 2>/dev/null | grep -oE '"POWER":"(ON|OFF)"' | cut -d':' -f2 | tr -d '"')
    if [[ -z "$status" ]]; then
        echo "UNKNOWN"
    else
        echo "$status"
    fi
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
        if [ "$DEVICE_STATUS" == "OFF" ] || [ "$DEVICE_STATUS" == "UNKNOWN" ]; then
            echo "Audio detected ($HIGHEST_LEVEL dB), turning on Tasmota device..."
            if curl -s --connect-timeout 5 --max-time 10 "$TASMOTA_ON" >/dev/null 2>&1; then
                echo "Successfully turned on Tasmota device"
            else
                echo "Failed to turn on Tasmota device"
            fi
        fi
    else
        NOW=$(date +%s)
        if (( NOW - LAST_ACTIVE > TIMEOUT )); then
            if [ "$DEVICE_STATUS" == "ON" ]; then
                echo "No audio for $((TIMEOUT/60)) minutes, turning off Tasmota device..."
                if curl -s --connect-timeout 5 --max-time 10 "$TASMOTA_OFF" >/dev/null 2>&1; then
                    echo "Successfully turned off Tasmota device"
                else
                    echo "Failed to turn off Tasmota device"
                fi
            elif [ "$DEVICE_STATUS" == "UNKNOWN" ]; then
                echo "Device status unknown, skipping power control"
            fi
        fi
    fi

    sleep 2
done

