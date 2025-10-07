#!/bin/sh

# Pulsar installer: POSIX sh, idempotent
# This script sets up ZDOTDIR (optional), installs bootstrapper, and updates ~/.zshrc

set -eu

# Portable "pipefail" approach: avoid pipelines and check command statuses explicitly.

usage() { printf '%s\n' "Usage: $0 [--channel=stable|edge] [--no-zdotdir]"; }

channel="stable"
no_zdotdir=0

for arg in "$@"; do
  case "$arg" in
    --channel=stable) channel="stable" ;;
    --channel=edge) channel="edge" ;;
    --channel=*) printf >&2 '%s\n' "Error: invalid channel '${arg#--channel=}'"; usage; exit 2 ;;
    --no-zdotdir) no_zdotdir=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf >&2 '%s\n' "Error: unknown option '$arg'"; usage; exit 2 ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  printf >&2 '%s\n' "Error: 'curl' is required. Install curl and rerun."
  exit 1
fi

# Determine target ZDOTDIR path (used for bootstrapper)
ZDOTDIR_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
target_zdotdir="$ZDOTDIR_DEFAULT"

# Ensure .zshenv exports ZDOTDIR, unless disabled (idempotent: append once, single backup)
zshenv="$HOME/.zshenv"
if [ "$no_zdotdir" -ne 1 ]; then
  line='export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"'
  if [ -f "$zshenv" ]; then
    if grep -Fxq "$line" "$zshenv"; then
      : # already present
    else
      ts="$(date -u +%Y%m%d%H%M%S)"
      cp -- "$zshenv" "$zshenv.pulsar.bak.$ts" 2>/dev/null || cp "$zshenv" "$zshenv.pulsar.bak.$ts"
      printf '%s\n' "$line" >>"$zshenv"
      printf '%s\n' "Updated ~/.zshenv ZDOTDIR"
    fi
  else
    ts="$(date -u +%Y%m%d%H%M%S)"
    printf '%s\n' "$line" >"$zshenv"
    printf '%s\n' "Updated ~/.zshenv ZDOTDIR"
  fi
fi

# Create ZDOTDIR/lib
mkdir -p -- "$target_zdotdir/lib" 2>/dev/null || mkdir -p "$target_zdotdir/lib"

# Write bootstrapper to $ZDOTDIR/lib/pulsar-bootstrap.zsh atomically
bootstrap_path="$target_zdotdir/lib/pulsar-bootstrap.zsh"
tmp_bootstrap="${bootstrap_path}.tmp.$$"

umask 022
cat >"$tmp_bootstrap" <<'ZSH_BOOTSTRAP'
# pulsar bootstrapper (zsh)
ZSH=${ZSH:-${ZDOTDIR:-$HOME/.config/zsh}}
mkdir -p "$ZSH/lib"
if [[ -f "$ZSH/lib/pulsar.zsh" ]]; then
  curl -fsSL -z "$ZSH/lib/pulsar.zsh" -o "$ZSH/lib/pulsar.zsh" https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh
else
  curl -fsSL -o "$ZSH/lib/pulsar.zsh" https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh
fi
source "$ZSH/lib/pulsar.zsh"
ZSH_BOOTSTRAP

if [ -f "$bootstrap_path" ]; then
  if cmp -s "$tmp_bootstrap" "$bootstrap_path"; then
    rm -f -- "$tmp_bootstrap"
  else
    mv -f -- "$tmp_bootstrap" "$bootstrap_path"
    printf '%s\n' "Bootstrapper updated"
  fi
else
  mv -f -- "$tmp_bootstrap" "$bootstrap_path"
  printf '%s\n' "Bootstrapper updated"
fi

# Prepare guarded block for ~/.zshrc
start_marker="# >>> pulsar >>>"
end_marker="# <<< pulsar <<<"

# Build desired block into BLOCK (literal $... preserved); channel is substituted here
BLOCK=$(cat <<EOF
$start_marker
ZSH=\${ZSH:-\${ZDOTDIR:-\$HOME/.config/zsh}}
export PULSAR_PROGRESS=auto
export PULSAR_COLOR=auto
export PULSAR_UPDATE_CHANNEL=$channel
export PULSAR_UPDATE_NOTIFY=1
PULSAR_PLUGINS=(
  zsh-users/zsh-completions
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
PULSAR_FPATH=(sindresorhus/pure)
PULSAR_PATH=(romkatv/zsh-bench)
source "\$ZSH/lib/pulsar-bootstrap.zsh"
$end_marker
EOF
)

# Ensure ~/.zshrc contains exactly one guarded block via awk (no duplicates)
zshrc="$HOME/.zshrc"
ts="$(date -u +%Y%m%d%H%M%S)"
tmp_zshrc="${zshrc}.tmp.$$"

# Detect if the block already exists to control backup behavior
had_block=0
if [ -f "$zshrc" ] && grep -q "^# >>> pulsar >>>\$" "$zshrc"; then
  had_block=1
fi

# Filter out any existing pulsar block
if [ -f "$zshrc" ]; then
  awk -v start="$start_marker" -v end="$end_marker" '
    BEGIN{inblk=0}
    $0==start{inblk=1; next}
    inblk==1 && $0==end{inblk=0; next}
    inblk==0{print}
  ' "$zshrc" >"$tmp_zshrc"
else
  : >"$tmp_zshrc"
fi

# Append a newline and BLOCK once at EOF
if [ -s "$tmp_zshrc" ]; then
  printf '\n' >>"$tmp_zshrc"
fi
printf '%s\n' "$BLOCK" >>"$tmp_zshrc"

# Only modify ~/.zshrc if content changed; single backup only on first insertion
if [ -f "$zshrc" ]; then
  if cmp -s "$tmp_zshrc" "$zshrc"; then
    rm -f -- "$tmp_zshrc"
  else
    if [ "$had_block" -eq 0 ]; then
      cp -- "$zshrc" "$zshrc.pulsar.bak.$ts" 2>/dev/null || cp "$zshrc" "$zshrc.pulsar.bak.$ts"
      printf '%s\n' "Inserted pulsar block into ~/.zshrc (backup at ~/.zshrc.pulsar.bak.$ts)"
    else
      printf '%s\n' "Updated ~/.zshrc pulsar block"
    fi
    mv -f -- "$tmp_zshrc" "$zshrc"
  fi
else
  mv -f -- "$tmp_zshrc" "$zshrc"
  printf '%s\n' "Inserted pulsar block into ~/.zshrc"
fi


exit 0