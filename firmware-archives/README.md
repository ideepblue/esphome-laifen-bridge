# Firmware Archives

This directory stores versioned firmware binaries for OTA rollback.

## Directory Structure

```
firmware-archives/
├── v1/
│   ├── esp32-c3-laifen-bridge-v1.ota.bin
│   ├── esp32-c3-laifen-bridge-v1.factory.bin
│   ├── esp32-c3supermini-laifen-bridge-v1.ota.bin
│   └── esp32-c3supermini-laifen-bridge-v1.factory.bin
├── v2/
│   └── ...
└── README.md
```

## How to Archive Firmware

After compiling, run:

```bash
# For ESP32-C3-DevKitM-1
./scripts/archive-firmware.sh v2 esp32-c3-laifen-bridge

# For Super Mini board
./scripts/archive-firmware.sh v2 esp32-c3supermini-laifen-bridge
```

## How to Rollback via OTA

1. Find the version you want to restore in this directory
2. Use ESPHome to upload the `.ota.bin` file:

```bash
# Via CLI
esphome upload laifen-bridge.yaml --device <ip-address> --file firmware-archives/v1/esp32-c3-laifen-bridge-v1.ota.bin

# Via Home Assistant
# Go to Settings → Devices → ESPHome → Update → Manual
```

## Version Naming

Simple version: `v1`, `v2`, `v3`...

## Current Versions

| Version | Date | Changes |
|---------|------|---------|
| v1 | 2026-06-04 | 初始版本（无版本号信息） |
| v2 | 2026-06-04 | 添加版本号、Fallback AP、组合命令 |
