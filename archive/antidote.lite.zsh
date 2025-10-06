#!/usr/bin/env zsh
# antidote.lite (deprecated) – compatibility shim for Pulsar
# This file remains for backward compatibility and now forwards to Pulsar.
# New installs should use pulsar.zsh instead.

# Map legacy variables to Pulsar defaults if set by users.
: ${PULSAR_HOME:=${ANTIDOTE_LITE_HOME:-${XDG_CACHE_HOME:-~/.cache}/pulsar}}
: ${PULSAR_GITURL:=${ANTIDOTE_LITE_GITURL:-https://github.com/}}

# Try to source a local pulsar.zsh (same directory), otherwise fetch from GitHub.
{
  emulate -L zsh
  set -o err_return
  local _src _dir
  _src=${${(%):-%x}:A}
  _dir=${_src:h}
  if [[ -r $_dir/pulsar.zsh ]]; then
    source $_dir/pulsar.zsh
  else
    # Fallback: source latest Pulsar from GitHub (no file writes).
    if (( $+commands[curl] )); then
      source <(curl -fsSL https://raw.githubusercontent.com/mattmc3/zsh_unplugged/main/pulsar.zsh)
    elif (( $+commands[wget] )); then
      source <(wget -q -O - https://raw.githubusercontent.com/mattmc3/zsh_unplugged/main/pulsar.zsh)
    else
      print -u2 "antidote.lite shim: couldn't find pulsar.zsh locally and neither curl nor wget is available."
      return 1
    fi
  fi
} || return 1
