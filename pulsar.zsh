# Pulsar - a micro zsh plugin manager inspired by antidote.
# author:  mattmc3 (adapted for Pulsar)
# home:    https://github.com/astrosteveo/pulsar
# license: https://unlicense.org
# usage:   plugin-load $myplugins
# version: 0.1.0

# Set variables.
: ${PULSAR_HOME:=${XDG_CACHE_HOME:-~/.cache}/pulsar}
: ${ZPLUGINDIR:=${ZSH_CUSTOM:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}/plugins}
typeset -gHa _pulsar_zopts=(extended_glob glob_dots no_monitor)
typeset -g PULSAR_FORCE_RECLONE=${PULSAR_FORCE_RECLONE:-}

# Pulsar update notifier config
typeset -g PULSAR_VERSION=${PULSAR_VERSION:-"v0.3.1"}  # current local version string
typeset -g PULSAR_UPDATE_CHANNEL=${PULSAR_UPDATE_CHANNEL:-"stable"}  # stable|edge|off
typeset -g PULSAR_UPDATE_CHECK_INTERVAL=${PULSAR_UPDATE_CHECK_INTERVAL:-86400}  # seconds
typeset -g PULSAR_UPDATE_NOTIFY=${PULSAR_UPDATE_NOTIFY:-1}  # 1=on, 0=off
typeset -g PULSAR_REPO=${PULSAR_REPO:-"astrosteveo/pulsar"} # Set the plugin upstream, set PULSAR_REPO to your fork if you wish to make Pulsar your own

# Progress output: 1=on, 0=off, auto=on for TTY only
typeset -g PULSAR_PROGRESS=${PULSAR_PROGRESS:-auto}
# Color output: auto=TTY only, 1=force, 0=off
typeset -g PULSAR_COLOR=${PULSAR_COLOR:-auto}
# Banner output: show one-line status after autorun; auto=TTY only, 1=force, 0=off
typeset -g PULSAR_BANNER=${PULSAR_BANNER:-auto}
# Update notifier cache/state helpers
pulsar__cache_dir() { print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/pulsar"; }
pulsar__state_file() { print -r -- "$(pulsar__cache_dir)/update_state"; }
pulsar__now() { print -r -- ${EPOCHSECONDS:-$(date +%s)}; }

# Progress/color helpers
pulsar__isatty() { [[ -t 1 ]]; }
pulsar__progress_on() {
  local v=${PULSAR_PROGRESS:-auto}
  [[ $v == 1 || ( $v == auto && $(pulsar__isatty; print $?) -eq 0 ) ]]
}
pulsar__color_on() {
  local v=${PULSAR_COLOR:-auto}
  [[ $v == 1 || ( $v == auto && $(pulsar__isatty; print $?) -eq 0 ) ]]
}
pulsar__cecho() {
  # usage: pulsar__cecho "text" [color_code]
  # color_code default 36 (cyan)
  pulsar__progress_on || return 0
  local msg=$1 col=${2:-36}
  if pulsar__color_on; then print -r -- "\e[${col}m$msg\e[0m"; else print -r -- "$msg"; fi
}

# Banner helpers (separate from progress)
pulsar__banner_on() {
  local v=${PULSAR_BANNER:-auto}
  [[ $v == 1 || ( $v == auto && $(pulsar__isatty; print $?) -eq 0 ) ]]
}
pulsar__banner() {
  local msg=$1 col=${2:-36}
  pulsar__banner_on || return 0
  if pulsar__color_on; then print -r -- "\e[${col}m$msg\e[0m"; else print -r -- "$msg"; fi
}

##? Clone zsh plugins in parallel.
function plugin-clone {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local spec repo ref plugdir processed_repo repo_part r
  local -A refmap
  local -Ua allrepos repos
  local -i installed_count=0 updated_count=0

  # Ensure base directory exists
  [[ -d $PULSAR_HOME ]] || command mkdir -p -- $PULSAR_HOME

  # Remove bare words ${(M)@:#*/*} and paths with leading slash ${@:#/*}.
  # Then split/join to keep the 2-part user/repo form to bulk-clone repos.
  for spec in ${${(M)@:#*/*}:#/*}; do
    ref=${spec##*@}
    repo=${spec%@*}

    # Split a single spec that may contain multiple repos respecting quotes
    for repo_part in ${(z)repo}; do
      # Normalize to owner/repo
      processed_repo=${(@j:/:)${(@s:/:)repo_part}[1,2]}
      allrepos+=($processed_repo)

      # Map ref if provided as @ref to normalized repo
      if [[ $repo_part == *"@"* ]]; then
        refmap[$processed_repo]=${repo_part##*@}
      fi

      # Build list of repos that need cloning
      if [[ -e $PULSAR_HOME/$processed_repo ]]; then
        if [[ -n $PULSAR_FORCE_RECLONE ]]; then
          command rm -rf -- $PULSAR_HOME/$processed_repo
          repos+=$processed_repo
        fi
      else
        repos+=$processed_repo
      fi
    done
  done

  # Clone missing repos
  for r in $repos; do
    plugdir=$PULSAR_HOME/$r
    # progress message per repo
    if [[ ! -d $plugdir ]]; then
      pulsar__cecho "Cloning ${r}..." 36
      (( installed_count++ ))
    elif [[ -d $plugdir/.git ]]; then
      pulsar__cecho "Updating ${r}..." 36
    else
      pulsar__cecho "Pulsar: Preparing $r" 36
    fi
    if [[ ! -d $plugdir ]]; then
      (
        command mkdir -p -- ${plugdir:h}
        local url="${PULSAR_GITURL:-https://github.com/}${r}.git"
        command git clone -q --depth 1 --recursive --shallow-submodules "$url" "$plugdir" || return
        # If a ref was provided for this repo, fetch and checkout it
        if [[ -n ${refmap[$r]-} ]]; then
          local _ref=${refmap[$r]}
          # Try fast paths: branch/tag names
          if ! command git -C $plugdir checkout -q --detach --force $_ref 2>/dev/null; then
            # Fallback: fetch the ref (commit or remote ref) shallowly then checkout
            command git -C $plugdir fetch -q --depth 1 origin $_ref || true
            command git -C $plugdir checkout -q --detach --force ${_ref} 2>/dev/null || true
          fi
        fi
        plugin-compile $plugdir || true
      ) &
    fi
  done
  wait

  # If repo already exists but a ref was requested, honor it
  local existing
  for existing in ${(u)allrepos}; do
    if [[ -d $PULSAR_HOME/$existing && -n ${refmap[$existing]-} ]]; then
      pulsar__cecho "Updating ${existing}..." 36
      (( updated_count++ ))
      (
        plugdir=$PULSAR_HOME/$existing
        local _ref=${refmap[$existing]}
        command git -C $plugdir fetch -q --depth 1 origin $_ref || true
        command git -C $plugdir checkout -q --detach --force ${_ref} 2>/dev/null || true
        plugin-compile $plugdir || true
      ) &
    fi
  done
  wait
  # Print final summary only when running in an interactive TTY.
  if pulsar__isatty; then
    (( installed_count + updated_count )) && pulsar__cecho "Pulsar: ${installed_count} installed, ${updated_count} updated" 32
  fi
}

##? Load zsh plugins.
function plugin-load {
  source <(plugin-script $@)
}

##? Script loading of zsh plugins.
function plugin-script {
  emulate -L zsh; setopt local_options $_pulsar_zopts

  # parse args
  local kind  # kind=path,fpath
  while (( $# )); do
    case $1 in
      -k|--kind)  shift; kind=$1 ;;
      -*)         echo >&2 "Invalid argument '$1'." && return 2 ;;
      *)          break ;;
    esac
    shift
  done

  local plugin src="source" inits=()
  (( ! $+functions[zsh-defer] )) || src="zsh-defer ."
  for plugin in $@; do
    if [[ -n "$kind" ]]; then
      if [[ "$kind" == "path" && -d $PULSAR_HOME/$plugin/bin ]]; then
        echo "path=(\$path $PULSAR_HOME/$plugin/bin)"
      else
        echo "$kind=(\$$kind $PULSAR_HOME/$plugin)"
      fi
    else
      inits=(
        {$ZPLUGINDIR,$PULSAR_HOME}/$plugin/${plugin:t}.{plugin.zsh,zsh-theme,zsh,sh}(N)
        $PULSAR_HOME/$plugin/*.{plugin.zsh,zsh-theme,zsh,sh}(N)
        $PULSAR_HOME/$plugin(N)
        ${plugin}/*.{plugin.zsh,zsh-theme,zsh,sh}(N)
        ${plugin}(N)
      )
      (( $#inits )) || { echo >&2 "No plugin init found '$plugin'." && continue }
      plugin=$inits[1]
      echo "fpath=(\$fpath $plugin:h)"
      echo "$src $plugin"
      [[ "$plugin:h:t" == zsh-defer ]] && src="zsh-defer ."
    fi
  done
}

##? Update plugins.
function plugin-update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local plugdir oldsha newsha
  for plugdir in $PULSAR_HOME/*/*/.git(N/); do
    plugdir=${plugdir:A:h}
    echo "Updating ${plugdir:h:t}/${plugdir:t}..."
    (
      oldsha=$(command git -C $plugdir rev-parse --short HEAD)
      command git -C $plugdir pull --quiet --ff --depth 1 --rebase --autostash
      newsha=$(command git -C $plugdir rev-parse --short HEAD)
      [[ $oldsha == $newsha ]] || echo "Plugin updated: $plugdir:t ($oldsha -> $newsha)"
    ) &
  done
  wait
  plugin-compile
  echo "Update complete."
}

##? Compile plugins.
function plugin-compile {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  autoload -Uz zrecompile
  local zfile
  for zfile in ${1:-$PULSAR_HOME}/**/*.zsh{,-theme}(N); do
    [[ $zfile != */test-data/* ]] || continue
    zrecompile -pq "$zfile"
  done
}

# Lightweight environment check
function pulsar-doctor {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local ok=1
  echo "Pulsar doctor"
  echo "  zsh:        $ZSH_VERSION"
  echo "  git:        $(command -v git >/dev/null && git --version || echo 'missing')"
  echo "  PULSAR_HOME: ${PULSAR_HOME}"
  echo "  GIT URL:    ${PULSAR_GITURL:-https://github.com/}"
  [[ -d $PULSAR_HOME ]] || { echo "  WARN: PULSAR_HOME does not exist"; ok=0; }
  command -v git >/dev/null || { echo "  ERROR: git not found"; ok=0; }
  if (( $#PULSAR_PLUGINS + $#PULSAR_PATH + $#PULSAR_FPATH > 0 )); then
    echo "  Declarative arrays detected: ok"
  else
    echo "  Declarative arrays: none (ok if using manual mode)"
  fi
  return $ok
}

# Update notifier functions

function pulsar__read_state {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  typeset -gA _pstate
  _pstate=()
  local f; f="$(pulsar__state_file)"
  if [[ -r "$f" ]]; then
    local k v
    while IFS='=' read -r k v; do
      [[ -z "$k" || "$k" == '#'* ]] && continue
      _pstate[$k]="$v"
    done < "$f"
  fi
}

function pulsar__write_state {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  typeset -gA _pstate
  local f tmp dir
  f="$(pulsar__state_file)"
  dir="${f:h}"
  command mkdir -p -- "$dir" 2>/dev/null || true
  tmp="${f}.$$"
  {
    [[ -n "${_pstate[last_check_epoch]-}" ]]      && print -r -- "last_check_epoch=${_pstate[last_check_epoch]}"
    [[ -n "${_pstate[last_seen_edge_sha]-}" ]]    && print -r -- "last_seen_edge_sha=${_pstate[last_seen_edge_sha]}"
    [[ -n "${_pstate[last_seen_stable_tag]-}" ]]  && print -r -- "last_seen_stable_tag=${_pstate[last_seen_stable_tag]}"
    [[ -n "${_pstate[last_seen_local_version]-}" ]] && print -r -- "last_seen_local_version=${_pstate[last_seen_local_version]}"
  } >| "$tmp" 2>/dev/null
  command mv -f -- "$tmp" "$f" 2>/dev/null || true
}


function pulsar__get_latest_tag {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  command -v git >/dev/null 2>&1 || return 1
  local url="https://github.com/${PULSAR_REPO}.git"
  local tags ts
  tags=$(command git ls-remote --tags "$url" 2>/dev/null) || return 1
  [[ -n "$tags" ]] || return 1
  ts=$(print -r -- "$tags" \
    | awk '{ s=$2; sub(/^refs\/tags\//,"",s); gsub(/\^\{\}/,"",s); print s }' \
    | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$')
  [[ -n "$ts" ]] || return 1
  if (print -r -- "$ts" | command sort -V >/dev/null 2>&1); then
    print -r -- "$ts" | command sort -V | tail -n1
  else
    # TODO: sort -V not available; fallback to lexicographic
    print -r -- "$ts" | command sort | tail -n1
  fi
}

function pulsar__get_main_sha {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  command -v git >/dev/null 2>&1 || return 1
  command git ls-remote "https://github.com/${PULSAR_REPO}.git" refs/heads/main 2>/dev/null | awk '{print $1}'
}

function pulsar__version_compare {
  # Compare two version strings (v1.2.3 format)
  # Usage: pulsar__version_compare <first_version> <second_version>
  # Returns 0 if first version is older than second version (second is newer), 1 otherwise.
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local v1="$1" v2="$2"
  
  # Strip leading 'v' if present
  v1="${v1#v}"
  v2="${v2#v}"
  
  # If versions are identical, v2 is not newer
  [[ "$v1" == "$v2" ]] && return 1
  
  # Use sort -V to compare versions
  local sorted
  if sorted=$(printf "%s\n%s\n" "$v1" "$v2" | command sort -V 2>/dev/null); then
    local -a lines
    lines=("${(@f)sorted}")
    local first_line="${lines[1]}"
    # If v1 comes first in sorted order, then v1 < v2, so v2 is newer
    [[ "$first_line" == "$v1" ]] && return 0
    return 1
  else
    # Fallback to lexicographic comparison if sort -V not available
    [[ "$v1" < "$v2" ]] && return 0
    return 1
  fi
}

function pulsar__notify_stable {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local current="$1" latest="$2"
  local yellow="" reset=""
  if command -v tput >/dev/null 2>&1; then
    yellow="$(tput setaf 3 2>/dev/null || true)"
    reset="$(tput sgr0 2>/dev/null || true)"
  fi
  print -r -- "${yellow}Pulsar update available: ${current} → ${latest} (stable). Release notes: https://github.com/${PULSAR_REPO}/releases/tag/${latest}${reset}"
}

function pulsar__notify_local_update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local current="$1"
  local yellow="" reset=""
  if command -v tput >/dev/null 2>&1; then
    yellow="$(tput setaf 3 2>/dev/null || true)"
    reset="$(tput sgr0 2>/dev/null || true)"
  fi
  [[ "$current" =~ '^v?[0-9]+\.[0-9]+\.[0-9]+$' ]] || return 0
  print -r -- "${yellow}Pulsar updated to ${current}. Release notes: https://github.com/${PULSAR_REPO}/releases/tag/${current}${reset}"
}

function pulsar__notify_edge {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local latest_sha="$1"
  local yellow="" reset=""
  if command -v tput >/dev/null 2>&1; then
    yellow="$(tput setaf 3 2>/dev/null || true)"
    reset="$(tput sgr0 2>/dev/null || true)"
  fi
  local short="${latest_sha[1,7]}"
  print -r -- "${yellow}Pulsar update available on main (edge). Latest: ${short}. Compare: https://github.com/${PULSAR_REPO}/compare/${latest_sha}..main${reset}"
}

function pulsar__check_update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  (( PULSAR_UPDATE_NOTIFY )) || return 0
  pulsar__read_state

  # Always show a one-time notice when a new local Pulsar version is first loaded,
  # regardless of network check intervals or channel settings.
  if [[ "${_pstate[last_seen_local_version]-}" != "$PULSAR_VERSION" ]]; then
    pulsar__notify_local_update "$PULSAR_VERSION"
    _pstate[last_seen_local_version]="$PULSAR_VERSION"
    pulsar__write_state
  fi

  [[ "$PULSAR_UPDATE_CHANNEL" == "off" ]] && return 0
  command -v git >/dev/null 2>&1 || return 0

  local now; now="$(pulsar__now)"
  local last="${_pstate[last_check_epoch]-0}"
  local interval="${PULSAR_UPDATE_CHECK_INTERVAL:-86400}"
  if (( now - last < interval )); then
    return 0
  fi

  case "$PULSAR_UPDATE_CHANNEL" in
    stable)
      local latest
      latest="$(pulsar__get_latest_tag)" || latest=""
      # Only notify if latest is non-empty and current version is older than latest
      if [[ -n "$latest" ]] && pulsar__version_compare "$PULSAR_VERSION" "$latest"; then
        pulsar__notify_stable "$PULSAR_VERSION" "$latest"
        _pstate[last_seen_stable_tag]="$latest"
      fi
      ;;
    edge)
      local remote_sha
      remote_sha="$(pulsar__get_main_sha)" || remote_sha=""
      if [[ -n "$remote_sha" && "$remote_sha" != "${_pstate[last_seen_edge_sha]-}" ]]; then
        pulsar__notify_edge "$remote_sha"
        _pstate[last_seen_edge_sha]="$remote_sha"
      fi
      ;;
    *)
      ;;
  esac

  _pstate[last_check_epoch]="$now"
  pulsar__write_state
}

# Optional declarative autorun: if arrays are set before sourcing, auto-clone and load.
# Configure in your .zshrc, then source this file:
#   PULSAR_PATH=(romkatv/zsh-bench)
#   PULSAR_FPATH=(sindresorhus/pure)
#   PULSAR_PLUGINS=(zsh-users/zsh-completions zsh-users/zsh-autosuggestions)
#   source $ZSH/lib/pulsar.zsh
# Control with:
#   PULSAR_NO_AUTORUN=1   # disable autorun even if arrays are set
#   PULSAR_AUTORUN=1      # force autorun regardless
#   PULSAR_AUTOCOMPILE=1  # run plugin-compile after loading
()
{
  local was_interactive=0
  [[ $- == *i* ]] && was_interactive=1
  emulate -L zsh; setopt local_options $_pulsar_zopts
  # Only autorun at source time if enabled or arrays are populated.
  local do_autorun=0
  if [[ -n ${PULSAR_AUTORUN-} ]]; then
    do_autorun=1
  elif (( $#PULSAR_PLUGINS + $#PULSAR_PATH + $#PULSAR_FPATH > 0 )); then
    do_autorun=1
  fi

  if (( ${+PULSAR_NO_AUTORUN} )); then
    do_autorun=0
  fi

  if (( do_autorun )); then
    local -Ua _all=()
    (( $#PULSAR_PLUGINS )) && _all+=$PULSAR_PLUGINS
    (( $#PULSAR_PATH ))    && _all+=$PULSAR_PATH
    (( $#PULSAR_FPATH ))   && _all+=$PULSAR_FPATH
    (( $#_all )) && plugin-clone $_all

    (( $#PULSAR_PATH ))  && plugin-load --kind path  $PULSAR_PATH
    (( $#PULSAR_FPATH )) && plugin-load --kind fpath $PULSAR_FPATH
    (( $#PULSAR_PLUGINS )) && plugin-load $PULSAR_PLUGINS

    [[ -n ${PULSAR_AUTOCOMPILE-} ]] && plugin-compile

    # Print a concise banner only for interactive shells
    if (( was_interactive )); then
      local _num_plugins=$#PULSAR_PLUGINS _num_path=$#PULSAR_PATH _num_fpath=$#PULSAR_FPATH
      pulsar__banner "Pulsar ready: plugins=${_num_plugins} path=${_num_path} fpath=${_num_fpath}" 36
    fi
  fi
}

# Trigger update check after initialization
if (( PULSAR_UPDATE_NOTIFY )); then
  pulsar__check_update
fi

# Convenience commands

##? Update Pulsar core (self) if curl is available, then re-source.
function pulsar-self-update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  # Resolve install base similarly to installer logic
  local base
  if [[ -n ${ZDOTDIR-} && $ZDOTDIR != $HOME ]]; then
    base=$ZDOTDIR
  else
    base=${XDG_CONFIG_HOME:-$HOME/.config}/zsh
  fi
  local dest="$base/lib/pulsar.zsh"
  if ! command -v curl >/dev/null 2>&1; then
    echo >&2 "pulsar-self-update: curl not found; skipping self-update."
    return 0
  fi
  local url="https://raw.githubusercontent.com/${PULSAR_REPO}/main/pulsar.zsh"
  if [[ -f "$dest" ]]; then
    command curl -fsSL -z "$dest" -o "$dest" "$url" || return 0
  else
    command curl -fsSL -o "$dest" "$url" || return 0
  fi
  source "$dest" 2>/dev/null || true
}

##? Update Pulsar and plugins.
function pulsar-update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  pulsar-self-update || true
  plugin-update
}
