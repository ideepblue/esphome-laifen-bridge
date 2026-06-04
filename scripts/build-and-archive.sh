#!/bin/bash
# Compile firmware for both boards and archive
# Usage: ./scripts/build-and-archive.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Load environment variables
if [ -f .env ]; then
    echo "Loading .env file..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Activate virtual environment if exists
if [ -f "../.venv/bin/activate" ]; then
    source ../.venv/bin/activate
fi

# Read version from YAML
VERSION=$(grep "firmware_version:" laifen-bridge.yaml | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Error: Cannot read firmware_version from YAML"
    exit 1
fi

echo "=========================================="
echo "Building firmware v${VERSION}"
echo "=========================================="

# Compile both boards
BOARDS=("laifen-bridge.yaml" "laifen-bridge-super-mini.yaml")

for CONFIG in "${BOARDS[@]}"; do
    echo ""
    echo "Compiling ${CONFIG}..."
    esphome compile "${CONFIG}"
    echo "Done: ${CONFIG}"
done

echo ""
echo "=========================================="
echo "Archiving firmware..."
echo "=========================================="

# Run archive script
./scripts/archive-firmware.sh

echo ""
echo "=========================================="
echo "Build complete! v${VERSION}"
echo "=========================================="
