#!/usr/bin/env bash
# Mac 机房一键准备：装 XcodeGen（无需管理员权限）并生成 Xcode 工程
set -euo pipefail
cd "$(dirname "$0")/.."

XCODEGEN_VERSION="2.44.1"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "[lab_setup] xcodegen not found, downloading prebuilt binary..."
  mkdir -p .tools
  if [ ! -x .tools/xcodegen/bin/xcodegen ]; then
    curl -fL --retry 3 -o /tmp/xcodegen.zip       "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
    rm -rf .tools/xcodegen
    unzip -q /tmp/xcodegen.zip -d .tools
  fi
  export PATH="$PWD/.tools/xcodegen/bin:$PATH"
fi

xcodegen --version
xcodegen generate
echo "[lab_setup] done. Open CamCardReplica.xcodeproj in Xcode."
