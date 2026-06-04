#!/bin/bash
# Archive compiled firmware for both boards
# Usage: ./scripts/archive-firmware.sh
# Automatically reads version from YAML and archives both boards

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Read version from YAML
VERSION=$(grep "firmware_version:" laifen-bridge.yaml | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Error: Cannot read firmware_version from YAML"
    exit 1
fi

echo "Firmware version: $VERSION"

# Archive both boards
BOARDS=("esp32-c3-laifen-bridge" "esp32-c3supermini-laifen-bridge")
ARCHIVE_DIR="firmware-archives/${VERSION}"

mkdir -p "${ARCHIVE_DIR}"

for BOARD in "${BOARDS[@]}"; do
    BUILD_DIR=".esphome/build/${BOARD}/.pioenvs/${BOARD}"

    if [ ! -d "${BUILD_DIR}" ]; then
        echo "Warning: Build directory not found for ${BOARD}, skipping..."
        continue
    fi

    cp "${BUILD_DIR}/firmware.ota.bin" "${ARCHIVE_DIR}/${BOARD}-${VERSION}.ota.bin"
    cp "${BUILD_DIR}/firmware.factory.bin" "${ARCHIVE_DIR}/${BOARD}-${VERSION}.factory.bin"
    echo "Archived: ${BOARD} ${VERSION}"
done

echo ""
echo "Archived to ${ARCHIVE_DIR}/"
ls -lh "${ARCHIVE_DIR}/"
