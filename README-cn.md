# Blueprint

**你说 WHAT，Blueprint 搞定 HOW。**

一个 OpenCode 命令：在你写代码之前自动完成类型定义、接口设计、数据流图、错误协议，然后多 LLM 审查，再按蓝图 TDD 编码。

你只需要回答：**这个功能做什么？**

---

## WHAT vs HOW

| 你（WHAT） | Blueprint（HOW） |
|---|---|
| 写 `design.md` 描述功能 | 提取核心实体，补漏边界条件 |
| 提供技术栈和约束 | 所有类型一个文件定稿 |
| 描述功能场景 | 画出完整数据流，每个分支不遗漏 |
| 告诉 agent 你的偏好 | 设计模块接口，确保无循环依赖 |
| **你花 ~5–10 分钟** | 定义错误处理规则：重试？报错？用户看到什么？ |
| | 从类型推测试边界，从数据流生成覆盖清单 |
| | 7 个 LLM 从安全/性能/架构/业务/角色扮演审查 |
| | 自动修 L1 问题，升级决策性问题给你 |
| | 按蓝图 TDD 编码，通过模块出口门 |
| | **全自动，~3–5 分钟完成设计+审查** |

---

## 有 Blueprint vs 没有

```
没有 Blueprint：
  你说做什么 → LLM 自由发挥 → 类型散落、接口冲突、错误被静默吞掉

有 Blueprint：
  你说做什么 → 自动设计 + 审查 → 按约束编码 → 一致、完整、可维护
```

---

## 工作流

```
Phase A（你，~5 分钟）    Phase B+C（自动，~3–5 分钟）    Phase D（自动，按需）
───────────────────      ──────────────────────────       ────────────────────────
写 design.md             /blueprint 触发                   按蓝图 TDD 编码
描述做什么               补缺口、问问题                      类型只能从 types.md 导入
                        4 阶段自动设计                      接口只能按 contracts.md
                        7 个 LLM 并行审查                   错误只能按 errors.md
                        输出 final report
```

### Phase A — 只回答 WHAT
写一份 `design.md`，自由格式。核心实体、模块划分、技术栈、场景。不需要模板。

### Phase B — BP 帮你查漏补缺
`/blueprint` 扫描你的设计，发现缺口就自然讨论。像和工程师聊天，不是填表格。

### Phase C — 全自动蓝图设计（3–5 分钟）
4 个阶段顺序执行 → `types.md` → `contracts.md` → `lifecycle.md` → `errors.md`，然后 7 个 LLM 并行审查（安全、性能、架构、业务、角色扮演、一致性，最后汇总为 final report）。

### Phase D — 按约束编码
TDD 硬约束：类型只从 `types.md` 来，接口只按 `contracts.md` 实现，错误只按 `errors.md` 处理。没有绕过途径。

---

## 快速开始

```bash
cd blueprint/
./install.sh
```

```bash
/blueprint                      # 全流程：设计 + 审查 + 编码
/blueprint --design-only        # 仅设计（不编码）
/blueprint --from-stage 3       # 中断后恢复
```

前提：项目根目录有 `design.md`。

---

## 产出

```
.blueprint/<topic>/
├── design.md              ← 你的设计（BP 补充后）
├── types.md               ← 所有类型，一次定稿
├── contracts.md           ← 模块接口
├── lifecycle.md           ← 数据流图，分支完整
├── errors.md              ← 错误规则（无沉默错误）
├── test-properties.md     ← 边界条件（P0/P1/P2）
├── test-coverage.md       ← 覆盖矩阵（P0 必过）
├── .gate-passed           ← 通关哨兵
└── reviews/
    ├── review-security.md
    ├── review-perf.md
    ├── review-arch.md
    ├── review-business.md
    ├── review-roleplay.md
    ├── review-consistency.md
    └── final-report.md    ← 审查汇总
```

---

## 什么时候用？

| 适合 Blueprint | 不需要 |
|---|---|
| 多文件功能开发 | 改变量名 |
| 设计决策多，需要想清楚再写 | 修拼写错误 |
| 核心路径，需要稳定性 | 快速原型 |
| 团队协作，需要设计文档 | 单行配置变更 |

---

[English version](README.md)
