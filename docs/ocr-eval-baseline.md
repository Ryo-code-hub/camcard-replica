# OCR / 字段解析评测基线（合成名片）

> 运行环境：GitHub Actions macOS runner + Apple Vision（VNRecognizeTextRequest，zh-Hans/en-US，accurate）。
> 运行命令：swift run --package-path Core OCREval sample_data artifacts/ocr_eval.json
> 结果文件：CI artifact ocr-eval（ocr_eval.json / ocr_eval.md）。

## 最新结果（6 张合成名片）

| 字段 | 正确 / 总数 | 准确率 |
| --- | --- | --- |
| name | 5 / 5 | 100.0% |
| company | 5 / 5 | 100.0% |
| jobTitle | 4 / 4 | 100.0% |
| mobile | 6 / 6 | 100.0% |
| officePhone | 1 / 1 | 100.0% |
| fax | 1 / 1 | 100.0% |
| email | 4 / 4 | 100.0% |
| website | 1 / 1 | 100.0% |
| address | 3 / 3 | 100.0% |

虚构字段数（Ground Truth 不存在但解析出来）：0

## 演进记录

| 版本 | 修正 | 结果 |
| --- | --- | --- |
| 初版 | - | name 80%、company 80%、jobTitle 75%、address 66.7% |
| 地址识别修复 | 地址关键词改为中英文强特征匹配，避免 rd 等缩写误伤人名 | address 100% |
| 职称修复 | “教授”等中文职称不再被当成两字姓名 | jobTitle 100%，name 100% |
| 竖版名片 | 提高测试图分辨率到 900×1500 | company 100% |

## 说明与后续

- 6 张合成名片只是冒烟基线；作业要求教师提供 30–50 张统一测试集，后续扩充到 30 张，覆盖中英/双语/竖版/多电话/字段缺失/低质量/复杂背景。
- 评测同时验证两件事：AI/OCR 输出的概率性（准确率）与“不虚构字段”（虚构数 0）。
- 失败样本的分析写入 docs/difference-analysis.md。
