#!/usr/bin/env bash
# 在 Mac 机房：启动模拟器、注入测试名片、安装并启动 App
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME="${1:-iPhone 16}"
APP_PATH="build/Build/Products/Debug-iphonesimulator/CamCardReplica.app"
BUNDLE_ID="com.ryocode.camcardreplica"

echo "[simulate] booting $DEVICE_NAME"
xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || true
open -a Simulator

echo "[simulate] injecting sample cards into Photos"
for f in sample_data/cards/card_01_en.png sample_data/cards/card_02_zh.png sample_data/cards/card_03_bi.png sample_data/cards/card_04_vertical.png; do
  xcrun simctl addmedia booted "$f" || true
done

echo "[simulate] installing app"
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"

mkdir -p artifacts/screenshots
echo "[simulate] ready. Example:"
echo "  xcrun simctl io booted screenshot artifacts/screenshots/T01_empty.png"
