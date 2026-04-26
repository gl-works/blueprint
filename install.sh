#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${HOME}/.config/opencode"

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  Blueprint Plugin Installer"
echo "┃  Design-first engineering for OpenCode"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# === Check OpenCode ===
if ! command -v opencode &>/dev/null; then
  echo "❌ OpenCode is not installed."
  echo "   Install from: https://opencode.ai/docs"
  exit 1
fi

echo "✓ OpenCode $(opencode --version 2>/dev/null || echo 'found')"

# === Verify config directory ===
if [ ! -d "$OPENCODE_CONFIG" ]; then
  echo "❌ OpenCode config directory not found at $OPENCODE_CONFIG"
  echo "   Run 'opencode' at least once to initialize it."
  exit 1
fi

# === Determine target directories ===
CMD_DIR="${OPENCODE_CONFIG}/command"

mkdir -p "$CMD_DIR"

# === Copy files ===
echo "  Installing command..."
cp "${SCRIPT_DIR}/src/commands/blueprint.md" "${CMD_DIR}/blueprint.md"
echo "  ✓ ${CMD_DIR}/blueprint.md"

echo "  Installing workflow (command-relative)..."
cp "${SCRIPT_DIR}/src/workflows/blueprint.workflow" "${CMD_DIR}/.blueprint.workflow"
echo "  ✓ ${CMD_DIR}/.blueprint.workflow"

# === Clean up old locations ===
OLD_WORKFLOW="${OPENCODE_CONFIG}/get-shit-done/workflows/blueprint.md"
if [ -f "$OLD_WORKFLOW" ]; then
  rm "$OLD_WORKFLOW"
  echo "  🗑 Removed old workflow from GSD directory (${OLD_WORKFLOW})"
fi

echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  Installation complete."
echo "┃"
echo "┃  Usage:"
echo "┃    /blueprint                    Run full pipeline (topic auto-detected)"
echo "┃    /blueprint --design-only      Design only, skip coding"
echo "┃    /blueprint --from-stage 2     Resume from Stage 2"
echo "┃"
echo "┃  Requirements:"
echo "┃    design.md in project root (Phase A: manual design doc)"
echo "┃"
echo "┃  Output:"
echo "┃    .blueprint/<topic>/           All artifacts"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
