#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Running core unit tests on macOS (no Simulator)…"
swift test "$@"
