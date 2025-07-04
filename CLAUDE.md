# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Linux audio bridge system that creates a multi-input audio device accepting both AirPlay and line-in (microphone) inputs. The system automatically manages amplifier control via Tasmota HTTP API, turning the amp on/off based on audio activity detection.

## Architecture

The system consists of several interconnected components:

1. **JACK Audio Server** (`start_jack.sh`) - Core audio routing daemon with real-time priority
2. **Shairport-Sync** (`start_shairport_sync.sh`) - AirPlay receiver that connects to JACK
3. **Audio Monitor** (`monitor.sh`) - Monitors audio levels and controls Tasmota-connected amplifier
4. **Health Check** (`jack_healthcheck.sh`) - Monitors JACK daemon health and restarts if needed
5. **SystemD Services** - Manages all components as system services with proper dependencies

## Key Components

### Audio Flow
- JACK daemon handles all audio routing at 44.1kHz with 512-sample buffer
- Line-in (system:capture_1) routes to both playback channels
- AirPlay audio (shairport-sync:out_L/R) routes to playback channels
- Audio monitoring samples from both inputs to detect activity

### Amplifier Control
- Tasmota device at 192.168.1.199 controls amplifier power
- Audio threshold: -35dB (configurable in monitor.sh:6)
- Auto-off timeout: 10 minutes of silence (configurable in monitor.sh:9)
- Automatic power-on when audio detected above threshold

### Service Dependencies
```
jackd.service (JACK daemon)
├── shairport.service (AirPlay receiver)
│   └── post_shairport.service (JACK port connections)
│       └── amp_control.service (Audio monitoring & power control)
└── jack-healthcheck.timer (Health monitoring)
```

## Development Commands

### SystemD Management
```bash
# Install and enable all services
./add-to-systemd.sh

# Check service status
systemctl --user status jackd.service
systemctl --user status shairport.service
systemctl --user status amp_control.service

# View logs
journalctl --user -u jackd.service -f
journalctl --user -u amp_control.service -f
tail -f logs/monitor.log

# List timers (health check)
systemctl --user list-timers --all
```

### JACK Audio Tools
```bash
# List JACK ports
jack_lsp

# Monitor audio levels
jack_meter system:capture_1
jack_meter shairport-sync:out_L

# Manual port connections
jack_connect system:capture_1 system:playback_1
jack_connect shairport-sync:out_L system:playback_1
```

### Tasmota Control
```bash
# Check amplifier status
curl -s "http://192.168.1.199/cm?cmnd=Power"

# Manual control
curl -XGET "http://192.168.1.199/cm?cmnd=Power%20ON"
curl -XGET "http://192.168.1.199/cm?cmnd=Power%20OFF"
```

### Audio System Configuration
```bash
# View/modify audio mixer settings
amixer -c 0 cset numid=8 0  # Capture Volume
amixer -c 0 cset numid=9 0  # Gain
```

## Important Configuration

### Audio Thresholds
- Modify `THRESHOLD` in monitor.sh:6 to adjust sensitivity
- Modify `TIMEOUT` in monitor.sh:9 to change auto-off delay
- JACK buffer size and sample rate in start_jack.sh:11

### Network Configuration
- Tasmota IP address in monitor.sh:15
- Ensure network connectivity for HTTP API calls

### Service Paths
- All scripts expect to run from `/home/dietpi/audiobridge/`
- Log files stored in `logs/` directory
- SystemD service files in `systemd.confs/`

## Log Files

- `logs/monitor.log` - Audio monitoring and amplifier control events
- `logs/jack.log` - JACK daemon output
- SystemD journal - Service status and errors

## Troubleshooting

### JACK Issues
- Health check timer automatically restarts unresponsive JACK daemon
- Manual restart: `systemctl --user restart jackd.service`
- Check audio device availability: `aplay -l`

### Audio Routing
- Use `jack_lsp` to verify port availability
- Check connections with `jack_lsp -c`
- Post-connection script runs 60 seconds after shairport starts

### Amplifier Control
- Monitor API responses in monitor.log
- Test Tasmota connectivity manually with curl commands
- Verify network connectivity to 192.168.1.199