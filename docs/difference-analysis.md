# 差异分析（Difference Analysis）

> 本文件逐项记录“复刻实现 vs 参考 App”的可观察差异、原因与处置。

## 平台差异（模拟器 vs 真机）

| 差异 | 原因 | 处置 |
| --- | --- | --- |
| 相机取景/拍摄在模拟器不可用 | iOS 模拟器无摄像头 | 模拟器用 MockCamera（内置测试名片模拟拍摄）；真机走系统 UIImagePickerController |
| 相机权限弹窗只在真机出现 | 模拟器无相机硬件 | requestCamera 用 AVCaptureDevice.authorizationStatus 分支；模拟器提示改用相册导入 |
| CamCard iOS 无法在模拟器安装 | 模拟器无 App Store | Week1 用借来的 iPhone 做黑盒观察，截图留档 |

## 实现差异（待机房实测补充）

| 项 | 参考行为（待观察确认） | 当前实现 | 备注 |
| --- | --- | --- | --- |
| 名片边界检测 | CamCard 自动检测并显示框 | Vision VNDetectRectanglesRequest + CropEditorView 四角手动调整 | 失败时兜底内缩裁剪并提示 |
| OCR | CamCard 自带 OCR | Apple Vision（中英） | 概率性：见 docs/ocr-eval-baseline.md |
| 字段抽取 | CamCard 结构化 | 规则式 FieldParser（不虚构字段） | 准确率见 CI ocr-eval |
| 导出 | 联系人/VCF | VCF 文件 + 系统分享 | 未实现写系统联系人（作业允许二选一） |
| UI | CamCard 视觉 | 系统风格 SwiftUI 简化版 | 待逐页对比截图 |

## 后续

- 30–50 张测试名片的字段级准确率与错误分析（当前 6 张基线 100%）
- UI 截图逐页对比（机房模拟器）
- 真机相机路径补充验证（若能借到 iPhone）
