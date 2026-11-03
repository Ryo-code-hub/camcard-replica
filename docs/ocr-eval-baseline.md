# OCR / 字段解析评测基线（合成名片 6 张）

> 运行环境：GitHub Actions macOS runner + Apple Vision（VNRecognizeTextRequest, zh-Hans/en-US, accurate）。
> 生成方式：swift run --package-path Core OCREval sample_data artifacts/ocr_eval.json

| 字段 | 正确 / 总数 | 准确率 |
| --- | --- | --- |
| name | 4 / 5 | 80.0% |
| company | 4 / 5 | 80.0% |
| jobTitle | 3 / 4 | 75.0% |
| mobile | 6 / 6 | 100.0% |
| officePhone | 1 / 1 | 100.0% |
| fax | 1 / 1 | 100.0% |
| email | 4 / 4 | 100.0% |
| website | 1 / 1 | 100.0% |
| address | 2 / 3 | 66.7% |

虚构字段数（Ground Truth 不存在但解析出来）：0

## 说明

- 这是修复“地址关键词误判”之前的基线；后续 CI 每次 push 都会重新评测（见 .github/workflows/ios.yml 的 ocr-eval job）。
- 失败样本：card_06（Apple / One Apple Park Way，地址与人名歧义）、card_04（竖版）、card_03（多电话）。
- 该评测同时验证：AI/OCR 输出的概率性（准确率）与“不虚构字段”（虚构数 0）。
