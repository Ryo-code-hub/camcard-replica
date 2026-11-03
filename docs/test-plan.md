# Reference Test Suite（T01–T20）

| ID | 名称 | 期望 | 实现/证据 | 状态 |
| --- | --- | --- | --- | --- |
| T01 | First Launch | 首次启动显示空名片夹与扫描入口 | 模拟器截图 + App 状态测试 | 待做 |
| T02 | Enter Scanner | 名片夹 → 扫描，进入相机页 | UI 截图 | 待做 |
| T03 | Permission | 相机权限允许/拒绝 → 行为符合规格；模拟器无相机 → 提示改用相册导入 | Mock/逻辑测试 + 说明 | 待做 |
| T04 | Capture | 拍摄标准名片 → 进入识别流程 | Mock 相机 + 真机 | 待做 |
| T05 | Import | 相册导入 → 进入识别流程 | 模拟器（simctl addmedia） | 待做 |
| T06 | Boundary Detection | 倾斜名片 → 识别并显示区域 + 透视校正 | 检测服务 + 截图 | 待做 |
| T07 | OCR | 标准测试名片 → 产生 OCR 原始文本 | OCR 批测脚本 | 待做 |
| T08 | Structured Extraction | OCR → 8 字段正确分类 | FieldParserTests | 待做 |
| T09 | Missing Field | 无名片 Website → 不得虚构 | FieldParserTests | 待做 |
| T10 | Multiple Phones | Mobile/Office/Fax 分类正确 | FieldParserTests | 待做 |
| T11 | Manual Correction | 修改字段 → 保存修改后结果 | UI 截图/手动 | 待做 |
| T12 | Save | 确认保存 → 返回列表出现新名片 | UI 测试 | 待做 |
| T13 | Detail | 详情显示全部保存字段 | UI 测试 | 待做 |
| T14 | Edit | 编辑 → 保存 → 页面更新 | UI 测试 | 待做 |
| T15 | Search | 姓名/公司/电话/Email 搜索 | RepositoryTests | 待做 |
| T16 | Tag | 加标签 → 按标签筛选 → 删除标签 | RepositoryTests | 待做 |
| T17 | Delete | 删除 → 列表消失 | RepositoryTests + UI | 待做 |
| T18 | Persistence | Kill → 重启 → 数据仍在 | RepositoryTests + 模拟器实测 | 待做 |
| T19 | Export | VCF 字段映射正确 | VCFExporterTests | 待做 |
| T20 | Exception | 取消/返回/权限拒绝/无法识别/空字段 | 手动 + 单元测试 | 待做 |
