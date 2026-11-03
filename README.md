# CamCard Replica（名片全能王功能切片复刻）

![iOS CI](https://github.com/Ryo-code-hub/camcard-replica/actions/workflows/ios.yml/badge.svg)

《移动应用开发》课程作业 1：基于 SDD 的“名片数字化与联系人管理”功能切片复刻。
技术栈：SwiftUI + MVVM + Vision（OCR / 矩形检测）+ Core Image（透视校正），本地 JSON 持久化，VCF/vCard 导出。

## 当前状态（2026-11-03）

| 模块 | 状态 | 证据 |
| --- | --- | --- |
| Core：模型/字段解析/仓库/VCF | ✅ | swift test 全绿（CI） |
| iOS App：列表/扫描/检测确认/OCR/校正/保存/详情/编辑/搜索/标签/VCF | ✅ 可构建 | xcodebuild 构建 + App 单元测试（CI） |
| OCR + 字段解析准确率 | ✅ 6 张合成名片 9 字段 100% | ocr-eval（CI artifact） |
| 模拟器实测截图 / 演示视频 | ⏳ 待 Mac 机房 | - |

## 仓库结构

| 目录 | 说明 |
| --- | --- |
| App/ | iOS App 源码（SwiftUI 视图、服务、ViewModel） |
| Core/ | 纯 Foundation 的 Swift Package：模型、字段解析、存储、VCF + 单元测试 + OCR 评测 CLI |
| project.yml | XcodeGen 工程描述（CI 与 Mac 机房都用它生成 Xcode 工程） |
| docs/ | spec、测试计划、差异分析、AI 协作记录、机房清单、OCR 评测基线 |
| scripts/ | 机房环境准备、构建、模拟器注入/截图脚本 |
| tools/ | 合成测试名片生成器、OCR 评测结果检查脚本 |
| sample_data/ | 合成测试名片 + Ground Truth JSON |

## 本地（Windows）开发

Windows 上做编码、文档与纯逻辑测试；iOS 编译/运行交给 GitHub Actions 或 Mac 机房。

    # 纯逻辑单元测试（需 Swift for Windows，可选）
    swift test --package-path Core

## Mac 机房快速开始

    git clone https://github.com/Ryo-code-hub/camcard-replica.git
    cd camcard-replica
    bash scripts/lab_setup.sh        # 下载 xcodegen（如未安装）+ 生成 Xcode 工程
    open CamCardReplica.xcodeproj    # 选 iPhone 16 模拟器，Run

更完整的机房流程见 docs/lab-workflow.md（含模拟器注入测试名片、截图、录屏命令）。

## CI（GitHub Actions，公开仓库免费 macOS 分钟）

- core-tests：swift test（CardCore）
- simulator-build：XcodeGen + xcodebuild 构建 iOS 模拟器 App
- app-tests：xcodebuild test（CardDraft / AppStore 单元测试）
- ocr-eval：Vision OCR + FieldParser 对合成名片集评测，输出字段准确率与虚构字段数

## 模拟器说明

iOS 模拟器没有摄像头：相机路径在模拟器上使用“测试图模拟拍摄”，真机上自动切换到系统相机；
相册导入在模拟器上通过“拖入图片 / simctl addmedia”完成。这一差异写入 docs/difference-analysis.md。

## 测试映射（Reference Test Suite T01–T20）

见 docs/test-plan.md；确定性用例尽量以 XCTest 落地在 Core/Tests、Tests/AppTests。
