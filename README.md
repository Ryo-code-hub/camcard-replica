# CamCard Replica（名片全能王功能切片复刻）

《移动应用开发》课程作业 1：基于 SDD 的“名片数字化与联系人管理”功能切片复刻。
技术栈：SwiftUI + MVVM + Vision（OCR / 矩形检测）+ Core Image（透视校正），本地 JSON 持久化，VCF/vCard 导出。

## 仓库结构

| 目录 | 说明 |
| --- | --- |
| App/ | iOS App 源码（SwiftUI 视图、服务、ViewModel） |
| Core/ | 纯 Foundation 的 Swift Package：数据模型、字段解析、存储、VCF 导出 + 单元测试 |
| project.yml | XcodeGen 工程描述（GitHub Actions 与 Mac 机房都用它生成 Xcode 工程） |
| docs/ | spec、测试计划、差异分析、AI 协作记录 |
| scripts/ | 机房环境准备、构建、截图脚本 |
| tools/ | 合成测试名片生成器（Pillow） |
| sample_data/ | 合成测试名片 + Ground Truth JSON |

## 本地（Windows）开发

Windows 上只做编码、文档和纯逻辑测试，不能编译 iOS UI：

    # 纯逻辑单元测试（需要 Swift for Windows，可选）
    swift test --package-path Core

没有 Mac 时，编译与运行靠 GitHub Actions 的 macOS runner 或学校 Mac 机房。

## Mac 机房快速开始

    cd CamCardReplica
    bash scripts/lab_setup.sh        # 下载 xcodegen（如果没装）+ 生成 Xcode 工程
    open CamCardReplica.xcodeproj    # 选 iPhone 16 模拟器，Run

## CI

- .github/workflows/ios.yml
  - Job 1：macOS 上跑 Core 单元测试（swift test）
  - Job 2：XcodeGen 生成工程，xcodebuild 构建 iPhone 模拟器 App

## 模拟器说明

iOS 模拟器没有摄像头：相机路径在模拟器上使用“测试图模拟拍摄”（MockCamera），
真机上自动切换到系统相机；相册导入在模拟器上通过“拖入图片/模拟器相册”完成。
这一差异会写入 docs/difference-analysis.md。

## 测试映射（Reference Test Suite T01–T20）

见 docs/test-plan.md。确定性用例尽量以 XCTest 形式落地在 Core/Tests 与 App 测试中。
