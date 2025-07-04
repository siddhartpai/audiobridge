# Audio Bridge System

A Linux-based multi-input audio bridge that seamlessly handles AirPlay and line-in (microphone) inputs with intelligent amplifier control.

## 🎯 Overview

This project creates a smart audio hub that:
- **Accepts multiple audio inputs** - AirPlay streaming and line-in (microphone) simultaneously
- **Automatic mixing** - No manual input switching required
- **Smart amplifier control** - Automatically powers on/off your amplifier based on audio activity
- **Professional audio routing** - Uses JACK for low-latency, high-quality audio processing

Perfect for home audio systems, podcasting setups, or any scenario where you need multiple audio inputs feeding into a single amplifier.

## ✨ Features

### Audio Processing
- **JACK Audio Server** - Professional, low-latency audio routing
- **Multi-input mixing** - Line-in and AirPlay streams mixed automatically
- **Real-time audio monitoring** - Detects audio activity for smart controls
- **Configurable audio thresholds** - Customizable sensitivity levels

### Smart Amplifier Control
- **Tasmota Integration** - Controls amplifier via HTTP API
- **Activity-based power management** - Turns amp on when audio detected
- **Configurable timeout** - Auto-off after specified silence period (default: 10 minutes)
- **Network resilience** - Handles connectivity issues gracefully

### System Management
- **SystemD integration** - Proper service management with dependencies
- **Health monitoring** - Automatic JACK daemon restart if unresponsive
- **Comprehensive logging** - All activities logged for troubleshooting
- **Flexible deployment** - Works from any directory location

## 📋 Requirements

### Hardware
- Linux device (tested on DietPi/Raspberry Pi)
- Audio interface with line-in capability
- Network-connected amplifier via Tasmota device
- Network connection for AirPlay

### Software Dependencies
- `jackd` - JACK Audio Connection Kit
- `shairport-sync` - AirPlay receiver
- `alsa-utils` - Audio mixer controls
- `curl` - HTTP requests for Tasmota control
- `bc` - Arithmetic calculations
- `systemd` - Service management

## 🚀 Quick Start

### 1. Clone and Install
```bash
git clone https://github.com/siddhartpai/jack.git
cd jack
./add-to-systemd.sh
```

### 2. Configure Tasmota (Optional)
```bash
# Set your Tasmota device IP
export TASMOTA_IP="192.168.1.199"
```

### 3. Check Status
```bash
systemctl --user status jackd.service
systemctl --user status amp_control.service
```

## 📖 Detailed Installation

### Step 1: Install Dependencies
```bash
# On DietPi/Debian/Ubuntu
sudo apt update
sudo apt install jackd2 shairport-sync alsa-utils curl bc

# Enable real-time audio (add to /etc/security/limits.conf)
echo "@audio - rtprio 95" | sudo tee -a /etc/security/limits.conf
echo "@audio - memlock unlimited" | sudo tee -a /etc/security/limits.conf
```

### Step 2: Clone Repository
```bash
git clone https://github.com/siddhartpai/jack.git
cd jack
```

### Step 3: Configure (Optional)
```bash
# Set custom Tasmota IP (default: 192.168.1.199)
export TASMOTA_IP="192.168.1.100"

# Set custom audio threshold (default: -35dB)
export THRESHOLD=-30

# Set custom timeout (default: 10 minutes)
export TIMEOUT=900  # 15 minutes
```

### Step 4: Install Services
```bash
./add-to-systemd.sh
```

The installation script will:
1. Stop any existing services
2. Update service files with current directory paths
3. Enable and start all services
4. Set up health monitoring

## ⚙️ Configuration

### Audio Settings
Edit `monitor.sh` to customize:
```bash
THRESHOLD=-35        # Audio detection threshold (dB)
TIMEOUT=$((10 * 60)) # Auto-off timeout (seconds)
```

### Tasmota Settings
Configure your amplifier's Tasmota device IP:
```bash
# Environment variable (temporary)
export TASMOTA_IP="192.168.1.100"

# Or edit monitor.sh directly
TASMOTA_IP="${TASMOTA_IP:-192.168.1.100}"
```

### JACK Audio Settings
Modify `start_jack.sh` for audio interface settings:
```bash
# Sample rate, buffer size, periods
jackd -P95 -d alsa -d hw:0,0 -p 512 -n 3 -r 44100
```

## 🔧 Service Management

### View Service Status
```bash
# Check all services
systemctl --user status jackd.service
systemctl --user status shairport.service
systemctl --user status amp_control.service

# Check health monitoring
systemctl --user list-timers --all
```

### View Logs
```bash
# System logs
journalctl --user -u jackd.service -f
journalctl --user -u amp_control.service -f

# Application logs
tail -f logs/monitor.log
```

### Manual Control
```bash
# Stop all services
systemctl --user stop amp_control.service
systemctl --user stop post_shairport.service  
systemctl --user stop shairport.service
systemctl --user stop jackd.service

# Start all services
./add-to-systemd.sh

# Restart specific service
systemctl --user restart jackd.service
```

## 🎵 Usage

### AirPlay Streaming
1. Connect your iOS/macOS device to the same network
2. Open Control Center → AirPlay
3. Select your device (configured in shairport-sync)
4. Audio automatically routes through the system

### Line-in Input
1. Connect microphone/instrument to line-in
2. Audio automatically mixes with any AirPlay streams
3. Both inputs feed to amplifier outputs

### Amplifier Control
- **Auto-on**: Amplifier turns on when audio detected above threshold
- **Auto-off**: Amplifier turns off after 10 minutes of silence
- **Manual control**: Use Tasmota web interface or HTTP API

## 🔍 Monitoring

### Audio Levels
```bash
# Monitor line-in
jack_meter system:capture_1

# Monitor AirPlay
jack_meter shairport-sync:out_L

# View all JACK connections
jack_lsp -c
```

### Amplifier Status
```bash
# Check power status
curl -s "http://192.168.1.199/cm?cmnd=Power"

# Manual control
curl "http://192.168.1.199/cm?cmnd=Power%20ON"
curl "http://192.168.1.199/cm?cmnd=Power%20OFF"
```

## 🛠️ Troubleshooting

### JACK Issues
```bash
# Check if JACK is responsive
jack_lsp

# Restart JACK
systemctl --user restart jackd.service

# Check audio devices
aplay -l
```

### AirPlay Issues
```bash
# Check shairport status
systemctl --user status shairport.service

# Check network connectivity
ping $(hostname -I | awk '{print $1}')

# Restart AirPlay services
systemctl --user restart shairport.service
systemctl --user restart post_shairport.service
```

### Amplifier Control Issues
```bash
# Test Tasmota connectivity
curl -s "http://192.168.1.199/cm?cmnd=Power"

# Check monitoring logs
tail -f logs/monitor.log

# Restart monitoring
systemctl --user restart amp_control.service
```

### Service Dependencies
If services fail to start, check dependencies:
```bash
# View service dependency tree
systemctl --user list-dependencies jackd.service

# Check for failed services
systemctl --user --failed
```

## 📁 Project Structure

```
jack/
├── README.md                   # This file
├── CLAUDE.md                   # Development guide
├── add-to-systemd.sh          # Installation script
├── start_jack.sh              # JACK daemon startup
├── start_shairport_sync.sh    # AirPlay receiver startup
├── post_shairport_sync.sh     # JACK port connections
├── monitor.sh                 # Audio monitoring & amp control
├── jack_healthcheck.sh        # JACK health monitoring
├── important_commands         # Useful commands reference
├── systemd.confs/            # SystemD service definitions
│   ├── jackd.service
│   ├── shairport.service
│   ├── post_shairport.service
│   ├── amp_control.service
│   ├── jack-healthcheck.service
│   └── jack-healthcheck.timer
└── logs/                     # Log files (created automatically)
    └── monitor.log
```

## 🔄 Development

### Making Changes
1. Edit scripts directly
2. Test changes: `./add-to-systemd.sh`
3. Monitor logs: `tail -f logs/monitor.log`
4. Check service status: `systemctl --user status <service>`

### Adding Features
- See `CLAUDE.md` for development guidance
- All paths are configurable via `BASE_DIR` environment variable
- Services use dependency management for proper startup order

## 🆘 Support

### Common Issues
- **"Permission denied"**: Ensure scripts are executable (`chmod +x *.sh`)
- **"JACK not found"**: Install `jackd2` package
- **"Amplifier not responding"**: Check Tasmota IP and network connectivity
- **"No audio"**: Verify audio device with `aplay -l` and JACK connections with `jack_lsp -c`

### Getting Help
1. Check logs: `journalctl --user -u <service-name> -f`
2. Verify dependencies: Run `./add-to-systemd.sh` and check error messages
3. Test components individually: Use manual commands from `important_commands`

## 📄 License

This project is open source. Feel free to modify and distribute according to your needs.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Note**: This system is designed for home/personal use. For production environments, consider additional security measures and monitoring.