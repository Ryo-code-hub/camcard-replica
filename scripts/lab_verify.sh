#!/usr/bin/env bash
# Mac 机房验收：构建 + 跑 Core 测试 + 启动模拟器
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="platform=iOS Simulator,name=iPhone 16"

echo "== 1/3 Core tests =="
swift test --package-path Core

echo "== 2/3 Build app for simulator =="
xcodebuild -project CamCardReplica.xcodeproj -scheme CamCardReplica \
  -configuration Debug -sdk iphonesimulator -destination "$DEST" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

echo "== 3/3 Boot simulator + install =="
xcrun simctl boot "iPhone 16" 2>/dev/null || true
open -a Simulator
APP_PATH=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 1 -name "CamCardReplica.app" | head -n 1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted com.ryocode.camcardreplica
echo "[lab_verify] app launched. Use: xcrun simctl io booted screenshot shot.png"
