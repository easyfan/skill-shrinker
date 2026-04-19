---
name: skill-shrink
description: 分析并压缩臃肿的 skill/agent/command 文件。当用户说"skill 太大了"、"shrink 这个 skill"、"帮我拆 skill"、"把 bash 提出去"、"skill 瘦身"、"命令怎么这么长"、"这个 command 好长"时触发。200-500 行给出拆分 proposal；>500 行分析后输出摘要，经用户确认后执行压缩。目标：稳定型 SKILL.md ≤ 220 行（ABCD 四类分层提取，共享参数物化到 manifest）；成长型 ≤ 80 行纯协调者（Phase agent 化，Proposal-only 输出）。
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# Skill Shrink

将单体 SKILL.md（或 command/agent .md 文件）拆分为分层结构：

```
skill-name/
├── SKILL.md                ← 协调者执行指令（Option A ≤ 220 行；Option B ≤ 80 行）
├── manifest-schema.json    ← 跨 Phase 共享参数（C2 类），init phase 写，后续只读
├── agents/                 ← 各 Phase agent 文件（Option B 专用）
├── scripts/                ← bash 实现细节（B 类）
└── DESIGN.md               ← 设计背景与推导（D 类，不被执行上下文加载）
```

---

## Step 0：测量与分级

首先确定目标文件路径：从用户消息或 `$ARGUMENTS` 中提取，赋给 `$TARGET_FILE`；`TARGET_DIR=$(dirname "$TARGET_FILE")`。若用户未指定，询问后继续。

```bash
wc -l "$TARGET_FILE"
```

| 行数 | 行动 |
|------|------|
| < 200 | 告知用户无需压缩，结束 |
| 200–500 | 扫描分析，输出 **Proposal**（建议，不执行）|
| > 500 | 分析后向用户确认，执行完整压缩流程（Step 1–4）|

---

## Step 0b（200-500 行）：输出 Proposal

读取全文，按 ABCD 四类标注内容（分类方法见 Step 0c）；同时统计以 `## Phase` 或 `## Step` 开头的独立执行阶段数量，赋给 `M`。输出以下格式：

```
📋 Shrink Proposal for <文件名>（当前 <N> 行）
可提取到 scripts/（B 类）：  - scripts/init_scratch.sh  （第 45-83 行，~39 行）
可物化到 manifest（C2 类）：  - 字体路径、LUFS 目标、像素参数  （第 XX-YY 行，~N 行）
可移入 DESIGN.md（D 类）：  - §阈值推导  （第 200-220 行，~20 行）
SKILL.md 预计压缩后：~<n> 行
<若 M ≥ 3>：另有 Option B（agent 化），输入 B 查看。
执行此方案？(y/n/B)  [n = 保持现状，结束]
```

等待用户确认后执行（选 B 则跳转 Step 4b 输出 Proposal-only）。

---

## Step 0c（> 500 行）：分析目标文件

读取全文，按以下四类标注：

**A 类（保留在 SKILL.md）：协调执行指令**
- 流程步骤、分支决策逻辑、格式/输出要求、对 Agent/子进程的调用说明

**B 类（→ scripts/）：bash 实现细节**
- 超过 3 行的 bash 代码块，且移出后 SKILL.md 只需单行调用替代

**C2 类（→ manifest-schema.json）：跨 Phase 共享参数**
→ 使用「C2 vs D 判断决策树」逐项裁定

统计 Phase 数量 M：识别以 `## Phase` 或 `## Step` 开头的独立执行阶段（不含分析/验证步骤）标题，计总数赋给 `M`。

**D 类（→ DESIGN.md）：设计背景与推导**
- 参数推导过程、架构决策理由、不影响执行的补充说明

输出分析摘要：
```
目标文件：<path>  当前行数：<N>
A 类（保留）：~<n> 行
B 类（bash 提取）：~<n> 行，建议脚本：<list>
C2 类（manifest 物化）：~<n> 行，建议字段：<list>
D 类（设计文档）：~<n> 行
检测到 Phase 数量：<M>
预计 SKILL.md 压缩后：~<n> 行

<若 M ≥ 3>：
检测到 <M> 个独立 Phase，推荐 Option B（agent 化）。
请选择：
  A — 稳定型（ABCD 提取，SKILL.md ≤ 220 行）
  B — 成长型（Phase agent 化 + manifest，Proposal-only）
```

等待用户选择 A/B 及脚本命名，再继续。

---

## C2 vs D 判断决策树

**步骤一**：该内容是否包含具体值（数字 / 路径 / 枚举 / schema）？
- 否 → **D 类**
- 是 → 步骤二

**步骤二**：该值是否在超过一个 Phase/Step 中被直接消费且必须完全一致？
- 否 → **D 类**；是 → **C2 类**（禁止移入 DESIGN.md）

**边界案例对照表**：

| 内容示例 | 类别 | 理由 |
|---------|------|------|
| LUFS 目标 = -14，Phase 2 和 Phase 4 均用 | C2 | 含具体值 + 多 Phase 消费 |
| 字体路径 `/System/.../Yuanti.ttc`，Phase 1/3 均用 | C2 | 含路径 + 多 Phase 消费 |
| 220 行阈值的推导公式 | D | 含数字但无执行链依赖 |
| 架构选型对比（为何不用 YAML） | D | 无具体执行值 |
| Phase 1 内部专用变量（bash 计算中间值） | B | 单 Phase 使用，不需物化；若为执行逻辑参数（无 bash 实现），归 A |

---

## Step 1（Option A）：提取 scripts/（B 类）

对每个 B 类代码块：

1. 命名脚本（动词_对象.sh，如 `init_scratch.sh`）
2. 写入 `scripts/`，固定开头：`#!/usr/bin/env bash` + `set -euo pipefail`；所有输入通过位置参数传入；stdout=结果，stderr=日志，exit code=0/1
3. SKILL.md 对应位置替换为：`bash "$TARGET_DIR/scripts/<脚本名>.sh" arg1 arg2`

---

## Step 2（Option A）：物化 C2 类 + 提取 D 类

### Step 2a：C2 → manifest-schema.json

将 C2 类内容写入 `$TARGET_DIR/manifest-schema.json`：
- 根层级为 dict；数组仅用于有序序列
- 由 init phase 一次性写入；后续每个 Phase 头部显式 Read 该文件，**禁止**推理 Phase 覆写
- SKILL.md 中对应位置替换为：`# 共享参数见 manifest-schema.json`

最小结构：
```json
{
  "version": "1.0",
  "shared": {
    "<参数名>": "<值（附单位/类型注释）>"
  }
}
```

### Step 2b：D → DESIGN.md

将 D 类内容整理到 `DESIGN.md`（开头加：`本文档记录设计决策，不被 CC 自动加载到执行上下文。`）；SKILL.md 对应位置替换为：`# 设计说明见 DESIGN.md §<节名>`

---

## Step 3（Option A）：精简 SKILL.md 正文

A 类内容保留，同步精简：
- 冗余注释（能从代码/脚本名称推断的）→ 删除
- 过度展开的步骤描述 → 压缩为要点（每个 Step ≤ 8 行）
- 重复路径字符串 → 确认已用变量替代

---

## Step 4a：验证（Option A）

```bash
wc -l "$TARGET_FILE"
# 目标 ≤ 220 行

for f in "$TARGET_DIR/scripts/"*.sh; do
  bash -n "$f" && echo "  ✓ $f" || echo "  ✗ $f 语法错误"
done
```

输出最终统计：SKILL.md、scripts/、manifest-schema.json、DESIGN.md 各项行数与压缩率。

若 SKILL.md 仍 > 220 行，检查遗漏的 B/C2/D 类内容，重复 Step 1-2，最多重试 2 次。若重试后仍 > 220 行，说明剩余内容均为 A 类，无法进一步压缩。

---

## Step 4b：Option B Proposal-only 输出

**Option B 当前为 Proposal-only 模式**：skill-shrink 仅输出 agent 化方案，实际拆分由用户手动执行。

```
📋 Option B Agent 化方案（Proposal-only，需手动执行）

建议目录结构：
  skill-name/
  ├── SKILL.md              ← 协调者，~<n> 行（仅含 Phase 调度顺序）
  ├── manifest-schema.json  ← 共享参数：<C2 字段列表>
  ├── agents/
  │   ├── phase-0-init.md   ← 读规范文件→写 manifest，~<n> 行
  │   ├── phase-1-xxx.md    ← 读 manifest，规则 inline 嵌入，~<n> 行
  │   └── ...（各 Phase 估算行数）
  └── DESIGN.md

新增 Phase 成本：+1 个 agent 文件，SKILL.md +1 行调用

完成后验证：
  □ wc -l SKILL.md ≤ 80
  □ ls agents/ 文件数与 Phase 数一致
  □ grep "manifest" agents/*.md 每个 agent 均有引用
```

---

## 典型拆分模式参考

| 原始模式 | 类别 | 迁移目标 |
|---------|------|---------|
| `mkdir -p + lock 检查 + 清理` 代码块 | B | `scripts/init_scratch.sh` |
| `wc -l + awk` 规模判断逻辑 | B | `scripts/compute_workload.sh` |
| 字体路径、LUFS 目标、像素参数（多 Phase 共用） | C2 | `manifest-schema.json` |
| 行数阈值推导公式、背景说明 | D | `DESIGN.md §阈值推导` |
| 架构对比说明（"为何不用 X"） | D | `DESIGN.md §设计决策` |
| Agent 成员一览表（纯说明） | D | `DESIGN.md §成员说明` |
