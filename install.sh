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

# Ensure .zshenv exports ZDOTDIR, unless disabled
zshenv="$HOME/.zshenv"
if [ "$no_zdotdir" -ne 1 ]; then
  if [ ! -f "$zshenv" ] || ! grep -Eqs '^[[:space:]]*export[[:space:]]+ZDOTDIR=' "$zshenv"; then
    ts="$(date -u +%Y%m%d%H%M%S)"
    if [ -f "$zshenv" ]; then
      cp -- "$zshenv" "$zshenv.pulsar.bak.$ts" 2>/dev/null || cp "$zshenv" "$zshenv.pulsar.bak.$ts"
    fi
    {
      printf '%s\n' '# Set ZDOTDIR to XDG-friendly location (managed by Pulsar installer)'
      printf '%s\n' 'export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"'
    } >>"$zshenv"
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
  fi
else
  mv -f -- "$tmp_bootstrap" "$bootstrap_path"
fi

# Prepare guarded block for ~/.zshrc
start_marker="# >>> pulsar >>>"
end_marker="# <<< pulsar <<<"

# Compose desired block into temp file
tmp_block="${HOME}/.pulsar.zshrc.block.$$"
: >"$tmp_block"
printf '%s\n' "$start_marker" >>"$tmp_block"
printf '%s\n' 'ZSH=${ZSH:-${ZDOTDIR:-$HOME/.config/zsh}}' >>"$tmp_block"
printf '%s\n' 'export PULSAR_PROGRESS=auto' >>"$tmp_block"
printf '%s\n' 'export PULSAR_COLOR=auto' >>"$tmp_block"
printf 'export PULSAR_UPDATE_CHANNEL=%s   # or edge if --channel=edge\n' "$channel" >>"$tmp_block"
printf '%s\n' 'export PULSAR_UPDATE_NOTIFY=1' >>"$tmp_block"
printf '%s\n' 'PULSAR_PLUGINS=(' >>"$tmp_block"
printf '%s\n' '  zsh-users/zsh-completions' >>"$tmp_block"
printf '%s\n' '  zsh-users/zsh-autosuggestions' >>"$tmp_block"
printf '%s\n' '  zsh-users/zsh-syntax-highlighting' >>"$tmp_block"
printf '%s\n' ')' >>"$tmp_block"
printf '%s\n' 'PULSAR_FPATH=(sindresorhus/pure)' >>"$tmp_block"
printf '%s\n' 'PULSAR_PATH=(romkatv/zsh-bench)' >>"$tmp_block"
printf '%s\n' 'source "$ZSH/lib/pulsar-bootstrap.zsh"' >>"$tmp_block"
printf '%s\n' "$end_marker" >>"$tmp_block"

# Ensure ~/.zshrc contains exactly one guarded block
zshrc="$HOME/.zshrc"
ts="$(date -u +%Y%m%d%H%M%S)"
tmp_zshrc="${zshrc}.tmp.$$"

if [ -f "$zshrc" ]; then
  # Filter out any existing pulsar block
  awk -v start="$start_marker" -v end="$end_marker" '
    BEGIN{inblk=0}
    $0==start{inblk=1; next}
    $0==end{inblk=0; next}
    inblk==0{print}
  ' "$zshrc" >"$tmp_zshrc"
else
  : >"$tmp_zshrc"
fi

# Append a newline and the desired block
if [ -s "$tmp_zshrc" ]; then
  printf '\n' >>"$tmp_zshrc"
fi
cat "$tmp_block" >>"$tmp_zshrc"

# Only modify ~/.zshrc if content changed
if [ -f "$zshrc" ]; then
  if cmp -s "$tmp_zshrc" "$zshrc"; then
    rm -f -- "$tmp_zshrc" "$tmp_block"
  else
    cp -- "$zshrc" "$zshrc.pulsar.bak.$ts" 2>/dev/null || cp "$zshrc" "$zshrc.pulsar.bak.$ts"
    mv -f -- "$tmp_zshrc" "$zshrc"
    rm -f -- "$tmp_block"
  fi
else
  mv -f -- "$tmp_zshrc" "$zshrc"
  rm -f -- "$tmp_block"
fi

printf '%s\n' "Pulsar install complete."
printf '%s\n' "Open a new terminal or run: source ~/.zshrc"
printf '%s\n' "To switch channels later: edit the Pulsar block in ~/.zshrc and set PULSAR_UPDATE_CHANNEL=stable|edge"

exit 0