# Mac 机房操作清单（本周 DDL 冲刺版）

> 机器：Mac Studio（Xcode 较新，默认按 Xcode 16+/iOS 18 或更新处理）。
> 先确认：Xcode 版本（xcodebuild -version）、可用模拟器（xcrun simctl list runtimes）。

## 第一次去机房（10 分钟）

    xcodebuild -version
    xcrun simctl list runtimes
    xcrun simctl list devices available | head -40

    git clone https://github.com/Ryo-code-hub/camcard-replica.git
    cd camcard-replica
    bash scripts/lab_setup.sh          # 没装 xcodegen 会自动下载到 .tools/
    open CamCardReplica.xcodeproj

Xcode 里：选 iPhone 16 / iOS 18 或更新模拟器 → Run。

## 每次去机房（30–60 分钟固定动作）

    cd camcard-replica
    git pull
    bash scripts/lab_verify.sh         # 跑 Core 测试 + 构建 + 启动模拟器

或者手动：

    swift test --package-path Core
    xcodebuild -project CamCardReplica.xcodeproj -scheme CamCardReplica -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

## 模拟器里注入测试名片（关键：模拟器没有摄像头）

    xcrun simctl boot "iPhone 16" 2>/dev/null || true
    xcrun simctl addmedia booted sample_data/cards/card_01_en.png
    xcrun simctl addmedia booted sample_data/cards/card_02_zh.png
    xcrun simctl addmedia booted sample_data/cards/card_03_bi.png
    xcrun simctl addmedia booted sample_data/cards/card_04_vertical.png

然后 App 里：扫描 → 相册导入 → 选刚注入的名片。

## 证据截图 / 演示视频

    xcrun simctl io booted screenshot artifacts/screenshots/T01_empty.png
    xcrun simctl io booted recordVideo artifacts/demo.mp4   # Ctrl+C 结束

建议截图清单：T01 空态、T02 扫描页、T05 导入、T06 检测/校正、T08 字段确认、T12 保存后列表、T13 详情、T15 搜索、T16 标签、T17 删除后、T18 重启后、T19 导出 VCF。

## 若机房时间紧

- 本机写完一批代码 → push → 去机房只做 git pull + scripts/lab_verify.sh + 截图。
- GitHub Actions 已自动跑 Core 测试与模拟器构建（本仓库公开，macOS 分钟数免费）。
- 模拟器没有摄像头：用“模拟拍摄（测试名片）”或相册导入；这是差异分析里要写的平台差异。
