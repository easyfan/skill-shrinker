# skill-shrinker

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

## Used by skill-review

skill-review (v1.5.0+) enforces a **400-line hard gate**: any target file exceeding 400 lines is
rejected with instructions to run `/skill-shrink` first. Install skill-shrinker alongside
skill-review to enable reviewing larger skill/agent files.

```
⛔ skill-review refuses to review files > 400 lines.
   Run /skill-shrink <file> first, then retry.
```

## Installation

### Option 1: Marketplace (recommended)

```
/plugin marketplace add skill-shrinker
/plugin install skill-shrinker@latest
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

skill-review will also guide you here automatically when a target file exceeds 400 lines.

## Output structure

```
my-skill/
├── SKILL.md        ← ≤220 lines, orchestration only
├── scripts/        ← extracted bash (each callable standalone)
│   ├── init_something.sh
│   └── check_format.sh
└── DESIGN.md       ← design notes, derivations, background
```

## Changelog

### v0.2.0 (2026-04-14)

skill-review integration — skill-shrinker is now a required companion for skill-review v1.5.0+:

| Item | Change |
|------|--------|
| Dependency role | skill-review v1.5.0 enforces a 400-line hard gate and instructs users to run `/skill-shrink` first |
| Post-install notice | install.sh now detects skill-review and confirms the companion relationship |
| README | Added "Used by skill-review" section |

### v0.1.0 (2026-03-01)

Initial release.

## License

MIT
