#!/bin/sh

# Pulsar installer

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

curl_present=1
if ! command -v curl >/dev/null 2>&1; then
  printf >&2 '%s\n' "Warning: 'curl' not found. The installer will still write configuration files but won't fetch runtime assets."
  curl_present=0
fi

# Default to XDG base directory specification
ZDOTDIR_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
respect_zdotdir=0
if [ -n "${ZDOTDIR:-}" ]; then
  respect_zdotdir=1
elif [ -f "$HOME/.zshenv" ] && grep -Eq '^export[[:space:]]+ZDOTDIR=' "$HOME/.zshenv"; then
  respect_zdotdir=1
fi
# For asset placement, prefer a respected ZDOTDIR when set AND not equal to $HOME; otherwise fallback to XDG default
if [ "$respect_zdotdir" -eq 1 ] && [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ]; then
  target_zdotdir="$ZDOTDIR"
else
  target_zdotdir="$ZDOTDIR_DEFAULT"
fi

# Do NOT modify ~/.zshenv. We only honor existing ZDOTDIR; we never set it.

# Create ZDOTDIR/lib
mkdir -p -- "$target_zdotdir/lib" 2>/dev/null || mkdir -p "$target_zdotdir/lib"

# Write bootstrapper to $ZDOTDIR/lib/pulsar-bootstrap.zsh atomically
bootstrap_path="$target_zdotdir/lib/pulsar-bootstrap.zsh"
tmp_bootstrap="${bootstrap_path}.tmp.$$"

umask 022
cat >"$tmp_bootstrap" <<'ZSH_BOOTSTRAP'
# pulsar bootstrapper (zsh)
ZSH=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
mkdir -p "$ZSH/lib"
if command -v curl >/dev/null 2>&1; then
  if [[ -f "$ZSH/lib/pulsar.zsh" ]]; then
    curl -fsSL -z "$ZSH/lib/pulsar.zsh" -o "$ZSH/lib/pulsar.zsh" https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh || true
  else
    curl -fsSL -o "$ZSH/lib/pulsar.zsh" https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh || true
  fi
fi
if [[ -f "$ZSH/lib/pulsar.zsh" ]]; then
  source "$ZSH/lib/pulsar.zsh"
fi
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
# Use ZDOTDIR if set, otherwise ZSH is set to th
if [[ -n \${ZDOTDIR-} && \$ZDOTDIR != \$HOME ]]; then
  ZSH=\$ZDOTDIR
else
  ZSH=\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh
fi
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

## Decide which zshrc to manage as the primary file
if [ "$respect_zdotdir" -eq 1 ] && [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ]; then
  zshrc="$target_zdotdir/.zshrc"
else
  zshrc="$HOME/.zshrc"
fi
ts="$(date -u +%Y%m%d%H%M%S)"
tmp_zshrc="${zshrc}.tmp.$$"

# Detect if the block already exists to control backup behavior
had_block=0
if [ -f "$zshrc" ] && grep -q "^# >>> pulsar >>>$" "$zshrc"; then
  had_block=1
fi

# Filter out any existing pulsar block and legacy bootstrap
legacy_flag="${tmp_zshrc}.legacy_removed"
rm -f -- "$legacy_flag" 2>/dev/null || true
if [ -f "$zshrc" ]; then
  # Remove any existing guarded pulsar block and legacy bootstrap lines.
  # Use sed for portability and simpler escaping across shells.
  sed -e "/^${start_marker}$/,/^${end_marker}$/d" \
      -e "/curl .*raw.githubusercontent.com\/.*\/pulsar\.zsh/d" \
      -e "/^source[[:space:]].*\/lib\/pulsar\.zsh$/d" \
      "$zshrc" >"$tmp_zshrc"
  if ! cmp -s "$zshrc" "$tmp_zshrc"; then
    printf '1' >"$legacy_flag"
  fi
else
  : >"$tmp_zshrc"
fi

# Append a newline and BLOCK once at EOF
if [ -s "$tmp_zshrc" ]; then
  printf '\n' >>"$tmp_zshrc"
fi
printf '%s\n' "$BLOCK" >>"$tmp_zshrc"

# Notify if legacy content was removed
if [ -f "$legacy_flag" ]; then
  printf '%s\n' "Removed legacy Pulsar bootstrap from ~/.zshrc"
  rm -f -- "$legacy_flag"
fi

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

# Add a VS Code compatibility shim in ~/.zshrc only when ZDOTDIR is honored (and not $HOME)
need_shim=0
if [ "$respect_zdotdir" -eq 1 ] && [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ]; then
  need_shim=1
fi
if [ "$need_shim" -eq 1 ]; then
  shim_rc="$HOME/.zshrc"
  shim_tmp="${shim_rc}.tmp.$$"
  shim_start="# >>> pulsar-zdotdir-shim >>>"
  shim_end="# <<< pulsar-zdotdir-shim <<<"
  SHIM_BLOCK=$(cat <<'EOS'
# >>> pulsar-zdotdir-shim >>>
# VS Code and some tools read ~/.zshrc directly. If ZDOTDIR points elsewhere, re-source the real config.
if [ "${TERM_PROGRAM:-}" = "vscode" ] && [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ] && [ -r "$ZDOTDIR/.zshrc" ]; then
  . "$ZDOTDIR/.zshrc"
fi
# <<< pulsar-zdotdir-shim <<<
EOS
)
  had_shim=0
  if [ -f "$shim_rc" ] && grep -q "^$shim_start$" "$shim_rc"; then
    had_shim=1
  fi
  if [ -f "$shim_rc" ]; then
    awk -v gbeg="$shim_start" -v gend="$shim_end" '
      $0==gbeg { inblk=1; next }
      inblk==1 && $0==gend { inblk=0; next }
      { print }
    ' "$shim_rc" >"$shim_tmp"
  else
    : >"$shim_tmp"
  fi
  if [ -s "$shim_tmp" ]; then printf '\n' >>"$shim_tmp"; fi
  printf '%s\n' "$SHIM_BLOCK" >>"$shim_tmp"
  if [ -f "$shim_rc" ]; then
    if cmp -s "$shim_tmp" "$shim_rc"; then
      rm -f -- "$shim_tmp"
    else
      if [ "$had_shim" -eq 0 ]; then
        cp -- "$shim_rc" "$shim_rc.pulsar-shim.bak.$ts" 2>/dev/null || cp "$shim_rc" "$shim_rc.pulsar-shim.bak.$ts"
      fi
      mv -f -- "$shim_tmp" "$shim_rc"
    fi
  else
    mv -f -- "$shim_tmp" "$shim_rc"
  fi
fi


exit 0
