---
name: skill-shrink
description: 分析并压缩臃肿的 skill/agent/command 文件。当用户说"skill 太大了"、"shrink 这个 skill"、"帮我拆 skill"、"把 bash 提出去"、"skill 瘦身"、"命令怎么这么长"、"这个 command 好长"时触发。200-500 行给出拆分 proposal；>500 行分析后输出摘要，经用户确认后执行压缩。目标：SKILL.md ≤ 220 行，bash 逻辑提取到 scripts/，设计文档移入 DESIGN.md。
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# Skill Shrink

将单体 SKILL.md（或 command/agent .md 文件）拆分为三层结构，把行数压缩到 220 行以内：

```
skill-name/
├── SKILL.md        ← 只保留协调者执行指令（目标 ≤ 220 行）
├── scripts/        ← 从 SKILL.md 提取的 bash 实现
└── DESIGN.md       ← 从 SKILL.md 提取的设计说明、推导、背景
```

---

## Step 0：测量与分级

首先确定目标文件路径：从用户消息或 `$ARGUMENTS` 中提取目标文件路径，赋给 `$TARGET_FILE`；`TARGET_DIR=$(dirname "$TARGET_FILE")`。若用户未指定文件，向用户询问后继续。

```bash
wc -l "$TARGET_FILE"
```

| 行数 | 行动 |
|------|------|
| < 200 | 告知用户无需压缩，结束 |
| 200–500 | 扫描分析，输出 **Proposal**（建议，不执行） |
| > 500 | 分析后向用户确认，执行完整压缩流程（Step 1-4） |

---

## Step 0b（200-500 行）：输出 Proposal

读取全文，识别 B/C 类内容，输出如下格式给用户确认：

```
📋 Shrink Proposal for <文件名>（当前 <N> 行）

可提取到 scripts/：
  - scripts/init_scratch.sh     （第 45-83 行，~39 行）
  - scripts/classify_files.sh  （第 90-128 行，~38 行）

可移入 DESIGN.md：
  - §阈值推导                   （第 200-220 行，~20 行）

SKILL.md 预计压缩后：~<n> 行

执行此方案？(y/n)
```

等待用户确认后，执行对应步骤（可只执行部分——用户可说"只提脚本，不要 DESIGN.md"）。

---

## Step 0c（> 500 行）：分析目标文件

读取目标文件，统计基准行数，并对全文内容做三类标注：

**A 类（保留在 SKILL.md）：协调者执行指令**
- 流程步骤（Step N：...）
- 对 Agent/子进程的调用说明
- 分支决策逻辑
- 格式/输出要求

**B 类（迁移到 scripts/）：bash 实现细节**
- 超过 3 行的 bash 代码块，且逻辑已充分表达于代码本身
- 可被参数化、独立测试的操作（初始化、文件分类、格式检查、工作量估算等）
- 判断标准：如果把这段 bash 移出去，SKILL.md 只需一行 `bash scripts/xxx.sh args` 就能替代，则属于 B 类

**C 类（迁移到 DESIGN.md）：设计说明与背景**
- 参数推导、公式、阈值来源
- 架构决策及其理由（"为什么这样设计"）
- 对比其他方案的分析
- 不影响执行的补充说明

输出分析摘要：
```
目标文件：<path>
当前行数：<N>
A 类（保留）：~<n> 行
B 类（bash 提取）：~<n> 行，建议脚本：<list>
C 类（设计文档）：~<n> 行
预计 SKILL.md 压缩后：~<n> 行
```

向用户确认分析结果和脚本命名，再继续。

---

## Step 1：提取 scripts/

对每个 B 类代码块：

1. 确定脚本名（动词_对象.sh，如 `init_scratch.sh`、`classify_files.sh`）
2. 写脚本文件到 `scripts/`，遵循约定：
   ```bash
   #!/usr/bin/env bash
   # <脚本名> — <一句话功能说明>
   # 用法：bash <脚本名>.sh arg1 arg2 ...
   # 退出码：0=成功, 1=失败
   set -euo pipefail
   ```
   - 所有输入通过位置参数传入，不读取环境变量
   - stdout = 结果数据；stderr = 错误/日志；exit code = 0/1
   - 若原代码块有 `eval "$(..."` 模式（输出 shell 变量赋值），保持该接口

3. 在 SKILL.md 对应位置用单行替换：
   ```bash
   bash "$TARGET_DIR/scripts/<脚本名>.sh" arg1 arg2
   ```

---

## Step 2：提取 DESIGN.md

将 C 类内容整理到 `DESIGN.md`：

- 每节加 `##` 标题（与原节名一致或更精炼）
- 开头加说明：`本文档记录设计决策，不被 CC 自动加载到执行上下文。`
- SKILL.md 中对应位置替换为一句引用（可选）：
  `# 设计说明见 DESIGN.md §<节名>`

---

## Step 3：精简 SKILL.md 正文

A 类内容保留，但同步做文字精简：

- 冗余的说明性注释（能从代码名称推断的）→ 删除
- 过度展开的步骤描述 → 压缩为要点
- 重复出现的路径字符串 → 确认已用变量替代
- 大段「背景说明」段落 → 移入 DESIGN.md

目标：每个 Step 的描述控制在 3-8 行以内。

---

## Step 4：验证

```bash
wc -l "$TARGET_FILE"
# 目标 ≤ 220 行

# 逐个脚本验证语法正确（不触发真实执行）
for f in "$TARGET_DIR/scripts/"*.sh; do bash -n "$f" && echo "  ✓ $f" || echo "  ✗ $f 语法错误"; done
```

输出最终统计：
```
原始行数：<N>
SKILL.md：<n> 行（压缩率 <x>%）
scripts/：<n> 行（<K> 个文件）
DESIGN.md：<n> 行
总计：<n> 行（膨胀率 <x>%，但 SKILL.md 目标达成）
```

若目标文件仍 > 220 行，检查是否有遗漏的 B/C 类内容，重复 Step 1-2；最多重试 2 次。若重试 2 次后仍 > 220 行，向用户说明剩余内容均为 A 类，无法进一步压缩，流程结束。

---

## 典型拆分模式参考

| 原始模式 | 迁移目标 |
|---------|---------|
| `mkdir -p + lock 检查 + 清理` 代码块 | `scripts/init_scratch.sh` |
| `wc -l + awk` 规模判断逻辑 | `scripts/compute_workload.sh` |
| `grep + stat` 文件分类判断 | `scripts/classify_files.sh` |
| 参数推导公式（如阈值计算） | `DESIGN.md §阈值推导` |
| 架构对比说明（"为何不用 X"） | `DESIGN.md §设计决策` |
| Agent 成员一览表（纯说明，不影响流程） | `DESIGN.md §成员说明` 或保留 |
