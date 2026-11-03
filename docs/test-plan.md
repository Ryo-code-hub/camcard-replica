# Reference Test Suite（T01–T20）

> 状态说明：已实现 = 代码与逻辑测试已落地；待机房 = 需要在 Mac 模拟器/真机上截图或手动验证；部分 = 模拟器限制或仍待补。

| ID | 名称 | 期望 | 实现/证据 | 状态 |
| --- | --- | --- | --- | --- |
| T01 | First Launch | 首次启动显示空名片夹与扫描入口 | CardListView 空态 + AppStoreTests | 已实现，待机房截图 |
| T02 | Enter Scanner | 名片夹 → 扫描，进入相机页 | ScanFlowView + 模拟器截图 | 已实现，待机房截图 |
| T03 | Permission | 权限允许/拒绝行为；模拟器无相机 → 提示相册导入 | requestCamera 分支 + 差异分析 | 部分（模拟器无相机） |
| T04 | Capture | 拍摄标准名片 → 进入识别流程 | 模拟拍摄（测试图）+ 真机相机 | 部分（模拟器用 Mock） |
| T05 | Import | 相册导入 → 进入识别流程 | PhotosPicker + simctl addmedia | 已实现，待机房截图 |
| T06 | Boundary Detection | 倾斜名片 → 显示检测区域 + 透视校正 | VNDetectRectanglesRequest + CropEditorView | 已实现，待机房截图 |
| T07 | OCR | 标准测试名片 → 产生 OCR 原始文本 | Vision OCR + CI ocr-eval | 已实现（CI 通过） |
| T08 | Structured Extraction | OCR → 8 字段正确分类 | FieldParserTests + ocr-eval | 已实现（CI 通过） |
| T09 | Missing Field | 无 Website → 不得虚构 | FieldParserTests + ocr-eval 虚构数 0 | 已实现（CI 通过） |
| T10 | Multiple Phones | Mobile/Office/Fax 分类正确 | FieldParserTests | 已实现（CI 通过） |
| T11 | Manual Correction | 修改字段 → 保存修改结果 | CardFormView + CardDraftTests | 已实现，待机房截图 |
| T12 | Save | 确认保存 → 列表出现新名片 | AppStoreTests + 模拟器实测 | 已实现，待机房截图 |
| T13 | Detail | 详情显示全部保存字段 | CardDetailView + 模拟器实测 | 已实现，待机房截图 |
| T14 | Edit | 编辑 → 保存 → 页面更新 | CardDetailView + AppStoreTests | 已实现，待机房截图 |
| T15 | Search | 姓名/公司/电话/Email 搜索 | RepositoryTests + AppStoreTests | 已实现（CI 通过） |
| T16 | Tag | 加标签 → 按标签筛选 → 删除标签 | RepositoryTests + TagManagerView | 已实现（CI 通过） |
| T17 | Delete | 删除 → 列表消失 | RepositoryTests + AppStoreTests | 已实现（CI 通过） |
| T18 | Persistence | Kill → 重启 → 数据仍在 | JSONFileCardStore + reload 测试 | 已实现逻辑，待机房实测 |
| T19 | Export | VCF 字段映射正确 | VCFExporterTests | 已实现（CI 通过） |
| T20 | Exception | 取消/返回/权限拒绝/无法识别/空字段 | failure 视图 + 单元测试 | 部分，待补全 |
