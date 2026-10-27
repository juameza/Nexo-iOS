#!/bin/bash
# Corre los tests igual que el CI. Uso: ./scripts/test.sh
set -euo pipefail

cd "$(dirname "$0")/.."

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

echo "▶️  Tests en: $DESTINATION"
xcodebuild test \
  -project RoadmapSwift.xcodeproj \
  -scheme RoadmapSwift \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
echo "✅ Todos los tests pasaron"
