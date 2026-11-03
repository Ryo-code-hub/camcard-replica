# Spec：名片数字化与联系人管理（功能切片）

> 状态：草稿（随实现迭代）。课程作业 1，CamCard 黑盒复刻。

## 1. 范围

功能闭环：名片夹首页 → 拍摄/导入 → 名片区域检测 → 透视/方向校正 → OCR → 字段结构化 → 人工校正 → 保存 → 详情 → 搜索/标签 → 持久化 → 导出。

不在范围：登录/会员/云同步/CRM/数字名片等（见作业第十五节）。

## 2. 参考环境

| 项 | 值 |
| --- | --- |
| 参考 App | 名片全能王（CamCard）iOS |
| 参考版本 | 待填（以老师锁定版本为准） |
| iOS 版本 | 待填 |
| 设备 | 待填 |
| 观察方式 | 借 iPhone 截图/录屏 + 流程记录 |

## 3. 数据模型（BusinessCard）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | UUID | 主键 |
| name / company / jobTitle | String | 允许空串 |
| mobiles / phones / faxes | [String] | 多值电话，分类保存 |
| emails | [String] | 多值邮箱 |
| website / address | String | 可为空 |
| tags | [String] | 标签 |
| notes | String | 备注 |
| originalImageFileName / processedImageFileName | String? | Documents 下图片名 |
| rawOCRText | String | OCR 原始文本（证据链） |
| createdAt / updatedAt | Date | 时间戳 |

## 4. 状态机（扫描流程）

    capture → processing(detect → correct → ocr → parse) → review → save → list
                ↘ error（可重试/重拍/取消）

## 5. 页面清单

| 页面 | 关键行为 | 对应测试 |
| --- | --- | --- |
| 名片夹首页 | 列表/空态/搜索/标签筛选/扫描入口/删除 | T01 T02 T15 T16 T17 |
| 扫描页（相机/导入） | 预览/拍摄/重拍/取消/相册导入/权限拒绝提示 | T02 T03 T04 T05 |
| 检测/校正页 | 显示检测区域/自动裁剪/透视校正/确认/重拍 | T06 |
| 识别中 | 进度与失败重试 | T07 |
| 字段确认页 | 8 字段可编辑/多值电话/多邮箱/标签/备注/保存 | T08–T12 |
| 详情页 | 查看图片/字段/编辑/删除/拨号/邮件/网址/导出 | T13 T14 T19 |

## 6. 判定规则（字段解析）

- 只允许从 OCR 文本中抽取，不得虚构原图不存在的信息（T09）。
- 电话分类：Mobile/手机/Cell 或中国手机号段 → mobiles；Tel/Office/座机 → phones；Fax/传真 → faxes（T10）。
- 姓名：优先顶部行，排除公司/职位/地址关键词，去掉 Dr./Mr./教授等称谓（Dr. David Chen → David Chen）。
- 公司：命中公司/学校/机构关键词的行；多个时优先“大学/公司/Inc”等强后缀。
- 地址：命中地址关键词的行，相邻行合并。

## 7. 验收

见 docs/test-plan.md（T01–T20）。
