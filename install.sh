#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# solana-surgeon-skill installer
# Surgical reasoning discipline for Claude Code agents on Solana.
# https://github.com/devIykee/solana-surgeon-skill
#
# Installs skill/, agents/, commands/, and rules/ into a Claude Code config
# directory and registers the skill in .claude/settings.json.
#
# Usage:
#   ./install.sh                 Install into ~/.claude (default)
#   ./install.sh --dir ./.claude Install into a specific .claude directory
#   ./install.sh --dry-run       Show what would happen, change nothing
#   ./install.sh --uninstall     Cleanly remove a previous installation
#   ./install.sh --help          Show this help

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; NC=""
fi

# ── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude"
SKILL_NAME="solana-surgeon-skill"
DRY_RUN=false
UNINSTALL=false

# Components copied verbatim into the target .claude directory.
COMPONENTS=(skill agents commands rules)

# ── Helpers ─────────────────────────────────────────────────────────────────
say()  { printf '%s\n' "$*"; }
info() { printf '%s→%s %s\n' "$BLUE" "$NC" "$*"; }
ok()   { printf '%s✓%s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$NC" "$*"; }
err()  { printf '%s✗%s %s\n' "$RED" "$NC" "$*" >&2; }

run() {
  # Echo in dry-run mode; execute otherwise.
  if $DRY_RUN; then
    printf '   %s[dry-run]%s %s\n' "$YELLOW" "$NC" "$*"
  else
    eval "$@"
  fi
}

print_help() {
  cat <<EOF
${BOLD}solana-surgeon-skill installer${NC}
Surgical reasoning discipline for Claude Code agents on Solana.

Usage:
  ./install.sh [options]

Options:
  --dir <path>   Target .claude directory (default: \$HOME/.claude)
  --dry-run      Show what would be installed without doing it
  --uninstall    Remove a previous solana-surgeon-skill installation
  -h, --help     Show this help

Repo: https://github.com/devIykee/solana-surgeon-skill
EOF
}

print_banner() {
  cat <<EOF
${BOLD}${RED}
   ╔══════════════════════════════════════════════╗
   ║          s o l a n a - s u r g e o n          ║
   ║   A surgeon does not guess. Neither do you.   ║
   ╚══════════════════════════════════════════════╝
${NC}
EOF
}

# ── Argument parsing ────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       TARGET_DIR="${2:?--dir requires a path}"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    -h|--help)   print_help; exit 0 ;;
    *)           err "Unknown option: $1"; print_help; exit 1 ;;
  esac
done

SETTINGS_FILE="$TARGET_DIR/settings.json"

# ── settings.json registration (idempotent) ─────────────────────────────────
# Adds {"solana-surgeon-skill": {"enabled": true}} under a top-level "skills"
# object. Uses jq when available; falls back to a safe manual write otherwise.
register_settings() {
  if $DRY_RUN; then
    printf '   %s[dry-run]%s register "%s" in %s\n' \
      "$YELLOW" "$NC" "$SKILL_NAME" "$SETTINGS_FILE"
    return
  fi

  mkdir -p "$TARGET_DIR"
  [ -f "$SETTINGS_FILE" ] || printf '{}\n' > "$SETTINGS_FILE"

  if command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    jq --arg name "$SKILL_NAME" \
      '.skills = (.skills // {}) | .skills[$name] = {"enabled": true}' \
      "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Registered $SKILL_NAME in settings.json (jq)"
  else
    if grep -q "\"$SKILL_NAME\"" "$SETTINGS_FILE" 2>/dev/null; then
      ok "settings.json already references $SKILL_NAME (no change)"
    else
      warn "jq not found — appending a minimal settings.json"
      cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
      cat > "$SETTINGS_FILE" <<EOF
{
  "skills": {
    "$SKILL_NAME": { "enabled": true }
  }
}
EOF
      warn "Wrote a fresh settings.json (previous saved as settings.json.backup)."
      warn "If you had other settings, merge them back from the backup."
    fi
  fi
}

unregister_settings() {
  [ -f "$SETTINGS_FILE" ] || return 0
  if $DRY_RUN; then
    printf '   %s[dry-run]%s remove "%s" from %s\n' \
      "$YELLOW" "$NC" "$SKILL_NAME" "$SETTINGS_FILE"
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    jq --arg name "$SKILL_NAME" \
      'if .skills then .skills |= del(.[$name]) else . end' \
      "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Removed $SKILL_NAME from settings.json"
  else
    warn "jq not found — leaving settings.json untouched; remove the"
    warn "\"$SKILL_NAME\" entry manually if present."
  fi
}

# ── Uninstall path ──────────────────────────────────────────────────────────
if $UNINSTALL; then
  print_banner
  info "Uninstalling $SKILL_NAME from $TARGET_DIR"
  for comp in "${COMPONENTS[@]}"; do
    dest="$TARGET_DIR/$comp/$SKILL_NAME"
    if [ -d "$dest" ]; then
      run "rm -rf \"$dest\""
      ok "Removed $comp/$SKILL_NAME"
    fi
  done
  unregister_settings
  say ""
  ok "${BOLD}$SKILL_NAME uninstalled. The theatre is clean.${NC}"
  exit 0
fi

# ── Install path ────────────────────────────────────────────────────────────
print_banner
$DRY_RUN && warn "DRY RUN — no files will be written."
info "Source: $SCRIPT_DIR"
info "Target: $TARGET_DIR"
say ""

installed=()
for comp in "${COMPONENTS[@]}"; do
  src="$SCRIPT_DIR/$comp"
  if [ ! -d "$src" ]; then
    warn "Skipping $comp/ (not found in source)"
    continue
  fi
  dest="$TARGET_DIR/$comp/$SKILL_NAME"
  run "mkdir -p \"$dest\""
  # Idempotent: clear any prior copy, then copy fresh contents.
  run "rm -rf \"$dest\""
  run "mkdir -p \"$dest\""
  run "cp -R \"$src/.\" \"$dest/\""
  count=$(find "$src" -type f | wc -l | tr -d ' ')
  installed+=("$comp/$SKILL_NAME ($count files)")
  ok "Installed $comp/ → $dest"
done

register_settings

# ── Confirmation ────────────────────────────────────────────────────────────
say ""
say "${BOLD}${GREEN}✓ solana-surgeon-skill installed. The surgeon is ready.${NC}"
say ""
say "${BOLD}Installed:${NC}"
for item in "${installed[@]}"; do
  say "  • $item"
done
say "  • settings.json entry: \"$SKILL_NAME\""
say ""
say "${BOLD}Next:${NC} open Claude Code and try"
say "  ${BLUE}/preflight pda${NC}      run the PDA pre-flight checklist"
say "  ${BLUE}/diagnose \"...\"${NC}     5-step diagnosis of an error"
say "  ${BLUE}/gate mainnet${NC}       stop-and-verify before a mainnet write"
say ""
say "  A surgeon does not guess. Neither does this skill."
