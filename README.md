# skill-shinker

Shrink bloated Claude Code skill/agent/command files into a clean three-layer structure.

## What it does

Analyzes a target SKILL.md (or command/agent .md) and compresses it to ≤220 lines by:

- Extracting bash logic → `scripts/` (each script independently testable)
- Moving design notes, derivations, background → `DESIGN.md` (not loaded into context)
- Keeping only orchestration instructions in SKILL.md

Three operating modes based on file size:

| Lines | Action |
|-------|--------|
| < 200 | Inform user: no compression needed |
| 200–500 | Output a **Proposal** (what to extract, estimated result) — does not modify files |
| > 500 | Execute full shrink automatically |

## Installation

### Option 1: Marketplace (recommended)

```
/plugin marketplace add skill-shinker
/plugin install skill-shinker@latest
```

### Option 2: Manual install

```bash
bash install.sh
```

Or with a custom Claude config directory (`CLAUDE_DIR`):

```bash
bash install.sh --target=/path/to/.claude
# or: CLAUDE_DIR=/path/to/.claude bash install.sh
```

Preview without writing:

```bash
bash install.sh --dry-run
```

Uninstall:

```bash
bash install.sh --uninstall
```

## Usage

After installation, trigger in Claude Code:

```
/skill-shrink my-skill
shrink ~/.claude/skills/my-skill/SKILL.md
this skill is getting too big, can you split it
```

## Output structure

```
my-skill/
├── SKILL.md        ← ≤220 lines, orchestration only
├── scripts/        ← extracted bash (each callable standalone)
│   ├── init_something.sh
│   └── check_format.sh
└── DESIGN.md       ← design notes, derivations, background
```

## License

MIT
