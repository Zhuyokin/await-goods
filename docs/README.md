# AwaitGoods Documentation Index

更新时间：2026-05-03

本目录用于存放 AwaitGoods 在工程根目录下统一维护的产品与提审文档，供开发、设计、上架和版本迭代共同使用。

## 目录目标

- 根级 `docs` 作为多语言文档主入口。
- 每个语种保持独立目录，统一包含技术支持、隐私政策、ASO 文案与截图文案。
- 与根级 `versions` 及项目 `readme.md` 保持联动，避免版本说明、上架文案和功能描述脱节。

## 当前语种

- `zh-Hans`
- `zh-Hant`
- `en`
- `ja`
- `ko`
- `de`
- `it`
- `fr`

## 标准文件结构

每个语种目录包含以下文件：

- `AwaitGoods-support.md`
- `AwaitGoods-privacy.md`
- `AwaitGoods-aso.md`
- `appstore-screenshot-text.md`

## ASO 文档排序规范

每份 `AwaitGoods-aso.md` 必须按以下顺序维护：

1. 基础资讯
2. 应用描述
3. 此版本新增内容
4. 关键词

补充要求：

- 副标题需控制在 30 个字符以内。
- 推广文案需控制在 170 个字符以内。
- 若包含审核说明、宣传文案或补充备注，需放在以上四部分之后。

## 与版本记录的同步规则

- 发布新版本时，先新增或更新 `versions/vx.y.z.md`。
- 同步更新各语种 `AwaitGoods-aso.md` 中的“此版本新增内容”。
- 若功能影响技术支持、隐私说明、截图卖点或多语言范围，需要同步更新对应语种文件。
- 每次版本更新后都要同步更新根目录 `readme.md`，保持文档入口、当前版本和维护规则一致。

## 历史内容来源

当前根级 `docs` 内容由 `ios/version` 下既有多语言文案整理而来。后续若继续保留 `ios/version`，应视为历史沉淀目录；根级 `docs` 为工程协作主入口。