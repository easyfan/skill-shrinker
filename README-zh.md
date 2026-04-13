# skill-shrinker

将臃肿的 Claude Code skill/agent/command 文件压缩为干净的三层结构。

## 功能

分析目标 SKILL.md（或 command/agent .md），通过以下方式压缩至 ≤220 行：

- 提取 bash 逻辑 → `scripts/`（每个脚本可独立测试）
- 将设计说明、推导过程、背景信息 → `DESIGN.md`（不加载至上下文）
- SKILL.md 仅保留编排指令

三种运行模式（按文件行数）：

| 行数 | 操作 |
|------|------|
| < 200 | 告知无需压缩 |
| 200–500 | 仅输出 **Proposal**（建议，不修改文件）|
| > 500 | 自动执行完整压缩流程 |

## 被 skill-review 依赖

skill-review（v1.5.0+）设有 **400 行强制拦截**：任何超过 400 行的目标文件将被拒绝审查，
并提示先运行 `/skill-shrink`。安装 skill-shrinker 后可解锁对大型 skill/agent 文件的审查能力。

```
⛔ skill-review 拒绝审查超过 400 行的文件。
   请先运行 /skill-shrink <文件>，再重新触发审查。
```

## 安装

### 方式一：从 marketplace 安装

```
/plugin marketplace add skill-shrinker
/plugin install skill-shrinker@latest
```

### 方式二：手动安装

```bash
bash install.sh
```

自定义 Claude 配置目录：

```bash
bash install.sh --target=/path/to/.claude
```

预览（不写入文件）：

```bash
bash install.sh --dry-run
```

卸载：

```bash
bash install.sh --uninstall
```

如需覆盖 `CLAUDE_DIR`：

```bash
CLAUDE_DIR=/custom/path bash install.sh
```

## 用法

安装后，在 Claude Code 中触发：

```
/skill-shrink my-skill
shrink ~/.claude/skills/my-skill/SKILL.md
这个 skill 太大了，帮我拆一下
```

skill-review 在目标文件超过 400 行时也会自动引导你执行 `/skill-shrink`。

## 输出结构

```
my-skill/
├── SKILL.md        ← ≤220 行，仅编排指令
├── scripts/        ← 提取的 bash 脚本（各脚本可独立调用）
│   ├── init_something.sh
│   └── check_format.sh
└── DESIGN.md       ← 设计说明、推导过程、背景信息
```

## 更新日志

### v0.2.0 (2026-04-14)

skill-review 集成 — skill-shrinker 成为 skill-review v1.5.0+ 的必要伴侣：

| 变更项 | 说明 |
|--------|------|
| 依赖关系 | skill-review v1.5.0 新增 400 行强制拦截，超限文件必须先经 `/skill-shrink` 处理 |
| 安装提示 | install.sh 安装完成后检测 skill-review，输出伴侣激活确认 |
| README | 新增"被 skill-review 依赖"章节 |

### v0.1.0 (2026-03-01)

初始版本。

## License

MIT
