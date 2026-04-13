#!/usr/bin/env bash
# scripts/install.sh — skill-shrinker plugin installer (core logic)
# Usage: ./install.sh [--dry-run] [--uninstall] [--target=<path>]
# Options:
#   --dry-run          Preview changes without writing
#   --uninstall        Remove installed files
#   --target=<path>    Custom Claude config directory (default: ~/.claude)
#   CLAUDE_DIR=<path>  Alternative to --target

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DRY_RUN=false
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --target=*)  CLAUDE_DIR="${arg#--target=}" ;;
  esac
done

SKILL_SRC="skills/skill-shrink"
SKILL_DST="skills/skill-shrink"

# ── Uninstall ──────────────────────────────────────────────────────────────────
if [ "$UNINSTALL" = true ]; then
  echo "Uninstalling skill-shrinker..."
  skill_dst="$CLAUDE_DIR/$SKILL_DST"
  if [ -d "$skill_dst" ]; then
    if $DRY_RUN; then
      echo "[dry-run] rm -rf $skill_dst"
    else
      rm -rf "$skill_dst"
      echo "  Removed: $skill_dst"
    fi
  else
    echo "  Not found (already removed?): $skill_dst"
  fi
  echo "Uninstall complete."
  exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────────
echo "Installing skill-shrinker..."

MODIFIED=0

install_dir() {
  local src="$PLUGIN_DIR/$1"
  local dst="$CLAUDE_DIR/$2"
  if $DRY_RUN; then
    echo "  1 file would be modified: $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -d "$dst" ]; then
    if diff -rq "$src" "$dst" > /dev/null 2>&1; then
      echo "  Unchanged: $dst"
      return
    fi
    rm -rf "$dst"
  fi
  cp -r "$src" "$dst"
  echo "  Installed: $dst"
  MODIFIED=$((MODIFIED + 1))
}

install_dir "$SKILL_SRC" "$SKILL_DST"

if $DRY_RUN; then
  echo "Dry run complete. No files written."
else
  echo ""
  echo "Done! $MODIFIED file(s) installed."
  if [ "$MODIFIED" -gt 0 ]; then
    echo ""
    echo "Usage: /skill-shrink <skill-name>"
    echo "  e.g. /skill-shrink my-skill"
  fi
  echo ""
  if [ -f "$CLAUDE_DIR/skills/skill-review/SKILL.md" ] || [ -f "$CLAUDE_DIR/commands/skill-review.md" ]; then
    echo "  ✓ skill-review detected — skill-shrinker is now active as a skill-review companion."
    echo "    Files >400 lines will be auto-gated and guided to /skill-shrink before review."
  else
    echo "  tip: install skill-review to unlock automatic 400-line gating:"
    echo "    /plugin marketplace add easyfan/skill-review"
  fi
fi
