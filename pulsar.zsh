# Pulsar - a micro zsh plugin manager inspired by antidote.
# author:  mattmc3 (adapted for Pulsar)
# home:    https://github.com/astrosteveo/pulsar
# license: https://unlicense.org
# usage:   plugin-load $myplugins
# version: 0.3.2

# Version tracking for update checks
# Testing interactive update prompt fix

# Set variables.
: ${PULSAR_HOME:=${XDG_CACHE_HOME:-~/.cache}/pulsar}
: ${ZPLUGINDIR:=${ZSH_CUSTOM:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}/plugins}
typeset -gHa _pulsar_zopts=(extended_glob glob_dots no_monitor)
typeset -g PULSAR_FORCE_RECLONE=${PULSAR_FORCE_RECLONE:-}

# Pulsar update notifier config
typeset -g PULSAR_VERSION=${PULSAR_VERSION:-"v0.3.2"}  # current local version string
typeset -g PULSAR_UPDATE_CHANNEL=${PULSAR_UPDATE_CHANNEL:-"stable"}  # stable|unstable|off ("edge" accepted as alias)
typeset -g PULSAR_UPDATE_CHECK_INTERVAL=${PULSAR_UPDATE_CHECK_INTERVAL:-86400}  # seconds
typeset -g PULSAR_UPDATE_NOTIFY=${PULSAR_UPDATE_NOTIFY:-1}  # 1=on, 0=off
typeset -g PULSAR_REPO=${PULSAR_REPO:-"astrosteveo/pulsar"} # Set the plugin upstream, set PULSAR_REPO to your fork if you wish to make Pulsar your own
typeset -g PULSAR_UPDATE_PROMPT=${PULSAR_UPDATE_PROMPT:-1} # 1=prompt interactively to update when available
typeset -g PULSAR_UPDATE_SHOW_NOTES=${PULSAR_UPDATE_SHOW_NOTES:-1} # 1=attempt to fetch and display release notes when interactive

# Progress output: 1=on, 0=off, auto=on for TTY only
typeset -g PULSAR_PROGRESS=${PULSAR_PROGRESS:-auto}
# Color output: auto=TTY only, 1=force, 0=off
typeset -g PULSAR_COLOR=${PULSAR_COLOR:-auto}
# Banner output: show one-line status after autorun; auto=TTY only, 1=force, 0=off (default: off for quiet shells)
typeset -g PULSAR_BANNER=${PULSAR_BANNER:-0}
# Update notifier cache/state helpers
pulsar__cache_dir() { print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/pulsar"; }
pulsar__state_file() { print -r -- "$(pulsar__cache_dir)/update_state"; }
pulsar__now() { print -r -- ${EPOCHSECONDS:-$(date +%s)}; }

##? Extract version string from a pulsar file (first match wins)
function pulsar__extract_version {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local file=$1 ver
  [[ -r $file ]] || return 1
  ver=$(sed -n -e 's/^# version: //p' \
             -e 's/^.*PULSAR_VERSION=.*\(v[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' \
             -e 's/.*version.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' "$file" | head -n1)
  [[ -z $ver ]] && return 1
  # Normalize to vX.Y.Z if needed
  if [[ $ver != v* && $ver =~ ^[0-9] ]]; then ver="v$ver"; fi
  print -r -- "$ver"
}

# Progress/color helpers
pulsar__isatty() { [[ -t 1 ]]; }
pulsar__progress_on() { local v=${PULSAR_PROGRESS:-auto}; [[ $v == 1 || ( $v == auto && pulsar__isatty ) ]]; }
pulsar__color_on()    { local v=${PULSAR_COLOR:-auto};   [[ $v == 1 || ( $v == auto && pulsar__isatty ) ]]; }
pulsar__cecho() {
  # usage: pulsar__cecho "text" [color_code]
  # color_code default 36 (cyan)
  pulsar__progress_on || return 0
  local msg=$1 col=${2:-36}
  if pulsar__color_on; then printf "\e[%sm%s\e[0m\n" "$col" "$msg"; else print -r -- "$msg"; fi
}

# Banner helpers (separate from progress)
pulsar__banner_on() {
  local v=${PULSAR_BANNER:-auto}
  [[ $v == 1 || ( $v == auto && pulsar__isatty ) ]]
}
pulsar__banner() {
  local msg=$1 col=${2:-36}
  pulsar__banner_on || return 0
  if pulsar__color_on; then printf "\e[%sm%s\e[0m\n" "$col" "$msg"; else print -r -- "$msg"; fi
}

##? Print a colorized message if colors are enabled
function pulsar__color_msg {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local col=$1; shift
  local msg=$*
  if pulsar__color_on; then
    if command -v tput >/dev/null 2>&1; then
      printf "%s%s%s\n" "$(tput setaf $col 2>/dev/null || echo)" "$msg" "$(tput sgr0 2>/dev/null || echo)"
    else
      printf "\e[%sm%s\e[0m\n" "$col" "$msg"
    fi
  else
    print -r -- "$msg"
  fi
}

##? Expand shorthand aliases for common plugin formats
function pulsar__expand_shorthand {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local spec="$1"
  # OMZP:: -> ohmyzsh/ohmyzsh/plugins/
  if [[ "$spec" == OMZP::* ]]; then
    spec="ohmyzsh/ohmyzsh/plugins/${spec#OMZP::}"
  # OMZL:: -> ohmyzsh/ohmyzsh/lib/
  elif [[ "$spec" == OMZL::* ]]; then
    spec="ohmyzsh/ohmyzsh/lib/${spec#OMZL::}"
  # OMZT:: -> ohmyzsh/ohmyzsh/themes/
  elif [[ "$spec" == OMZT::* ]]; then
    spec="ohmyzsh/ohmyzsh/themes/${spec#OMZT::}"
  fi
  print -r -- "$spec"
}

##? Clone zsh plugins in parallel.
function plugin-clone {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local spec repo ref plugdir processed_repo repo_part r original_spec
  local -A refmap specmap
  local -Ua allrepos repos all_specs
  local -i installed_count=0 updated_count=0

  # Ensure base directory exists
  [[ -d $PULSAR_HOME ]] || command mkdir -p -- $PULSAR_HOME

  # First expand all shorthand specs, then filter for remote repos
  for spec in $@; do
    # Expand shorthand first
    local expanded_spec=$(pulsar__expand_shorthand "$spec")
    # Keep specs that look like repos (contain /) and aren't local paths
    if [[ "$expanded_spec" == */* && "$expanded_spec" != /* ]]; then
      all_specs+="$spec"
    fi
  done
  
  # Process expanded specs
  for spec in $all_specs; do
    # Save original spec before expansion for better error messages
    original_spec="$spec"
    spec=$(pulsar__expand_shorthand "$spec")
    
    ref=${spec##*@}
    repo=${spec%@*}

    # Split a single spec that may contain multiple repos respecting quotes
    for repo_part in ${(z)repo}; do
      # Normalize to owner/repo
      processed_repo=${(@j:/:)${(@s:/:)repo_part}[1,2]}
      allrepos+=($processed_repo)
      
      # Map original spec to processed repo for better messages
      specmap[$processed_repo]="$original_spec"

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
    # Get the display spec (original with subdirectory if provided)
    local display_spec="${specmap[$r]:-$r}"
    # Remove @ref from display for cleaner output
    display_spec="${display_spec%@*}"
    
    # progress message per repo
    if [[ ! -d $plugdir ]]; then
      pulsar__cecho "Cloning ${display_spec}..." 36
      (( installed_count++ ))
    elif [[ -d $plugdir/.git ]]; then
      pulsar__cecho "Updating ${display_spec}..." 36
    else
      pulsar__cecho "Pulsar: Preparing ${display_spec}" 36
    fi
    if [[ ! -d $plugdir ]]; then
      (
        command mkdir -p -- ${plugdir:h}
        local url="${PULSAR_GITURL:-https://github.com/}${r}.git"
        if ! command git clone -q --depth 1 --recursive --shallow-submodules "$url" "$plugdir" 2>/dev/null; then
          echo >&2 "Pulsar: Failed to clone ${display_spec} (repository may not exist)"
          return 1
        fi
        # If a ref was provided for this repo, fetch and checkout it
        if [[ -n ${refmap[$r]-} ]]; then
          local _ref=${refmap[$r]}
          # Try fast paths: branch/tag names
          if ! command git -C $plugdir checkout -q --detach --force $_ref 2>/dev/null; then
            # Fallback: fetch the ref (commit or remote ref) shallowly then checkout
            command git -C $plugdir fetch -q --depth 1 origin $_ref 2>/dev/null || true
            if ! command git -C $plugdir checkout -q --detach --force ${_ref} 2>/dev/null; then
              echo >&2 "Pulsar: Warning: Failed to checkout ref '${_ref}' for ${display_spec}"
            fi
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

  local plugin src="source" inits=() expanded_plugin
  (( ! $+functions[zsh-defer] )) || src="zsh-defer ."
  for plugin in $@; do
    # Expand shorthand aliases
    expanded_plugin=$(pulsar__expand_shorthand "$plugin")
    
    if [[ -n "$kind" ]]; then
      # Support local absolute/relative paths as well as repo specs; compute target dir once
      local _dir
      if [[ "$expanded_plugin" == /* || "$expanded_plugin" == ./* || "$expanded_plugin" == ../* ]]; then
        _dir=$expanded_plugin
      else
        _dir=$PULSAR_HOME/$expanded_plugin
      fi
      if [[ "$kind" == "path" ]]; then
        if [[ -d "$_dir/bin" ]]; then
          echo "path=(\\$path $_dir/bin)"
        else
          echo "path=(\\$path $_dir)"
        fi
      else
        echo "$kind=(\\$$kind $_dir)"
      fi
    else
      # For plugins with subdirectories (e.g., ohmyzsh/ohmyzsh/plugins/git),
      # look for init files in the full path, not just based on the tail
      inits=(
        {$ZPLUGINDIR,$PULSAR_HOME}/$expanded_plugin/${expanded_plugin:t}.{plugin.zsh,zsh-theme,zsh,sh}(N)
        $PULSAR_HOME/$expanded_plugin/*.{plugin.zsh,zsh-theme,zsh,sh}(N)
        $PULSAR_HOME/$expanded_plugin(N)
        ${expanded_plugin}/*.{plugin.zsh,zsh-theme,zsh,sh}(N)
        ${expanded_plugin}(N)
      )
      if (( ! $#inits )); then
        echo >&2 "Pulsar: No plugin init found for '$plugin' (expanded to '$expanded_plugin')."
        echo >&2 "Pulsar: Looked in: $PULSAR_HOME/$expanded_plugin"
        continue
      fi
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
  # Backward-compatibility: migrate legacy edge state to unstable state
  if [[ -n "${_pstate[last_seen_edge_sha]-}" && -z "${_pstate[last_seen_unstable_sha]-}" ]]; then
    _pstate[last_seen_unstable_sha]="${_pstate[last_seen_edge_sha]}"
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
  [[ -n "${_pstate[last_seen_unstable_sha]-}" ]]    && print -r -- "last_seen_unstable_sha=${_pstate[last_seen_unstable_sha]}"
    [[ -n "${_pstate[last_seen_stable_tag]-}" ]]  && print -r -- "last_seen_stable_tag=${_pstate[last_seen_stable_tag]}"
    [[ -n "${_pstate[last_seen_local_version]-}" ]] && print -r -- "last_seen_local_version=${_pstate[last_seen_local_version]}"
    [[ -n "${_pstate[update_channel_migrated_from_edge]-}" ]] && print -r -- "update_channel_migrated_from_edge=${_pstate[update_channel_migrated_from_edge]}"
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

function pulsar__notify_stable {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local current="$1" latest="$2"
  local yellow="" reset=""
  if command -v tput >/dev/null 2>&1; then
    yellow="$(tput setaf 3 2>/dev/null || true)"
    reset="$(tput sgr0 2>/dev/null || true)"
  fi
  pulsar__color_msg 3 "Pulsar update available: ${current} → ${latest} (stable). Release notes: https://github.com/${PULSAR_REPO}/releases/tag/${latest}"
}

function pulsar__notify_local_update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local current="$1"
  local yellow="" reset=""
  if command -v tput >/dev/null 2>&1; then
    yellow="$(tput setaf 3 2>/dev/null || true)"
    reset="$(tput sgr0 2>/dev/null || true)"
  fi
  # Validate simple semver-like version string before printing
  if ! print -r -- "$current" | command grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+$'; then
    return 0
  fi
  pulsar__color_msg 3 "Pulsar updated to ${current}. Release notes: https://github.com/${PULSAR_REPO}/releases/tag/${current}"
}

function pulsar__notify_unstable {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local latest_sha="$1"
  local short="${latest_sha[1,7]}"
  pulsar__color_msg 3 "Pulsar update available on main (unstable). Latest: ${short}. Compare: https://github.com/${PULSAR_REPO}/compare/${latest_sha}..main"
}

# Backwards compatibility wrapper for older callers
function pulsar__notify_edge { pulsar__notify_unstable "$@" }

##? Attempt to fetch and display release notes (interactive only)
function pulsar__show_release_notes {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local tag="$1"
  (( PULSAR_UPDATE_SHOW_NOTES )) || return 0
  ! pulsar__isatty && return 0
  command -v curl >/dev/null 2>&1 || return 0
  # Prefer python3 for robust JSON parsing
  if command -v python3 >/dev/null 2>&1; then
    local body
    body=$(command curl -s "https://api.github.com/repos/${PULSAR_REPO}/releases/tags/${tag}" 2>/dev/null \
      | command python3 -c 'import sys,json
try:
  o=json.load(sys.stdin)
  print(o.get("body",""))
except Exception:
  pass' 2>/dev/null)
    if [[ -n $body ]]; then
      echo "\n=== Release notes (${tag}) ==="
      # Print a reasonable preview
      print -r -- "${body}" | sed -n '1,40p'
      echo "=== End release notes ===\n"
    fi
  fi
}

##? Prompt the user (interactive) to self-update now
function pulsar__maybe_prompt_update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local kind="$1" value="$2"
  ! pulsar__isatty && return 0
  # For stable releases show release notes first
  if [[ "$kind" == "stable" && -n "$value" ]]; then
    pulsar__show_release_notes "$value"
  fi
  (( PULSAR_UPDATE_PROMPT )) || return 0
  # Ask the user if they'd like to update now
  if read -q "REPLY?Pulsar: update available. Update now? (y/N) "; then
    echo
    if [[ $REPLY == [yY] ]]; then
      pulsar-self-update
    fi
  else
    echo
  fi
}

function pulsar__check_update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  (( PULSAR_UPDATE_NOTIFY )) || return 0
  pulsar__read_state

  [[ "$PULSAR_UPDATE_CHANNEL" == "off" ]] && return 0
  command -v git >/dev/null 2>&1 || return 0

  local now; now="$(pulsar__now)"
  local last="${_pstate[last_check_epoch]-0}"
  local interval="${PULSAR_UPDATE_CHECK_INTERVAL:-86400}"
  if (( now - last < interval )); then
    return 0
  fi

  local _chan=${PULSAR_UPDATE_CHANNEL}
  # If users still use legacy 'edge', warn and treat as alias for 'unstable'.
  if [[ "$_chan" == "edge" ]]; then
    # If this installation is already v1.x or newer, migrate automatically and persist a marker
    if print -r -- "$PULSAR_VERSION" | command grep -Eq '^v[1-9]'; then
      pulsar__color_msg 3 "Auto-migrating update channel from 'edge' to 'unstable' for Pulsar version $PULSAR_VERSION"
      _chan=unstable
      _pstate[update_channel_migrated_from_edge]=1
      pulsar__write_state
    else
      # Pre-v1.0: warn about deprecation but accept as alias
      if pulsar__isatty; then
        pulsar__color_msg 3 "DEPRECATION: PULSAR_UPDATE_CHANNEL='edge' is deprecated. Use 'unstable' instead.\nThis will be auto-migrated at Pulsar v1.0 if you do not change it."
      else
        printf '%s\n' "Pulsar: WARNING: PULSAR_UPDATE_CHANNEL='edge' is deprecated; please use 'unstable'" >&2
      fi
      _chan=unstable
    fi
  fi
  case "$_chan" in
    stable)
      local latest
      latest="$(pulsar__get_latest_tag)" || latest=""
      if [[ -n "$latest" && "$latest" != "$PULSAR_VERSION" ]]; then
        pulsar__notify_stable "$PULSAR_VERSION" "$latest"
        _pstate[last_seen_stable_tag]="$latest"
        pulsar__maybe_prompt_update stable "$latest"
      fi
      ;;
    unstable)
      local remote_sha
      remote_sha="$(pulsar__get_main_sha)" || remote_sha=""
      if [[ -n "$remote_sha" && "$remote_sha" != "${_pstate[last_seen_unstable_sha]-}" ]]; then
        pulsar__notify_unstable "$remote_sha"
        _pstate[last_seen_unstable_sha]="$remote_sha"
        pulsar__maybe_prompt_update unstable "$remote_sha"
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
    # Helper to parse unified specs like path:owner/repo or fpath:/local/dir
    local _kind _target
    pulsar__parse_spec() {
      local spec="$1"; _kind=source; _target="$spec"
      if [[ "$spec" == fpath:* ]]; then
        _kind=fpath; _target="${spec#fpath:}"
      elif [[ "$spec" == path:* ]]; then
        _kind=path; _target="${spec#path:}"
      fi
      # Expand shorthand in the target
      _target=$(pulsar__expand_shorthand "$_target")
    }

    # Use legacy arrays if provided, else treat PULSAR_PLUGINS as ordered list
    local use_legacy=0
    (( $#PULSAR_PATH + $#PULSAR_FPATH > 0 )) && use_legacy=1

    if (( use_legacy )); then
      local -Ua _all=()
      (( $#PULSAR_PLUGINS )) && _all+=$PULSAR_PLUGINS
      (( $#PULSAR_PATH ))    && _all+=$PULSAR_PATH
      (( $#PULSAR_FPATH ))   && _all+=$PULSAR_FPATH
      (( $#_all )) && plugin-clone $_all

      (( $#PULSAR_PATH ))    && plugin-load --kind path  $PULSAR_PATH
      (( $#PULSAR_FPATH ))   && plugin-load --kind fpath $PULSAR_FPATH
      (( $#PULSAR_PLUGINS )) && plugin-load $PULSAR_PLUGINS
    else
      local spec
      local -Ua _repos_to_clone=()
      for spec in $PULSAR_PLUGINS; do
        pulsar__parse_spec "$spec"
        # Only clone GitHub-like repos (owner/repo possibly with @ref); skip local paths
        if [[ "$_target" == */* && "$_target" != /* && "$_target" != ./* && "$_target" != ../* ]]; then
          _repos_to_clone+="$_target"
        fi
      done
      (( $#_repos_to_clone )) && plugin-clone $_repos_to_clone

      for spec in $PULSAR_PLUGINS; do
        pulsar__parse_spec "$spec"
        case $_kind in
          path)  plugin-load --kind path  "$_target" ;;
          fpath) plugin-load --kind fpath "$_target" ;;
          *)     plugin-load               "$_target" ;;
        esac
      done
    fi

    [[ -n ${PULSAR_AUTOCOMPILE-} ]] && plugin-compile

    # Print a concise banner only for interactive shells
    if (( was_interactive )); then
      if (( use_legacy )); then
        local _num_plugins=$#PULSAR_PLUGINS _num_path=$#PULSAR_PATH _num_fpath=$#PULSAR_FPATH
        pulsar__banner "Pulsar ready: plugins=${_num_plugins} path=${_num_path} fpath=${_num_fpath}" 36
      else
        local _num_ordered=$#PULSAR_PLUGINS
        pulsar__banner "Pulsar ready: entries=${_num_ordered} (ordered)" 36
      fi
    fi
  fi
}

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
    return 1
  fi

  # Determine channel and source URL
  local _chan=${PULSAR_UPDATE_CHANNEL:-stable}
  [[ "$_chan" == "edge" ]] && _chan=unstable  # Handle legacy alias
  local url branch_or_tag current_id new_id

  case "$_chan" in
    stable)
      echo "Updating Pulsar from ${PULSAR_REPO:-astrosteveo/pulsar} (stable channel)..."
      # Get latest stable tag
      branch_or_tag=$(pulsar__get_latest_tag 2>/dev/null)
      if [[ -z "$branch_or_tag" ]]; then
        echo "Failed to determine latest stable release; falling back to main"
        branch_or_tag=main
      fi
      url="https://raw.githubusercontent.com/${PULSAR_REPO:-astrosteveo/pulsar}/${branch_or_tag}/pulsar.zsh"
      current_id=$(pulsar__extract_version "$dest" 2>/dev/null || echo "unknown")
      ;;
    unstable)
      echo "Updating Pulsar from ${PULSAR_REPO:-astrosteveo/pulsar} (unstable channel: main branch)..."
      branch_or_tag=main
      url="https://raw.githubusercontent.com/${PULSAR_REPO:-astrosteveo/pulsar}/main/pulsar.zsh"
      # For unstable, show commit SHA if available
      current_id=$(pulsar__get_main_sha 2>/dev/null)
      [[ -n "$current_id" ]] && current_id="${current_id[1,7]}" || current_id="unknown"
      ;;
    off)
      echo "Note: Update channel is 'off', but proceeding with self-update from main..."
      branch_or_tag=main
      url="https://raw.githubusercontent.com/${PULSAR_REPO:-astrosteveo/pulsar}/main/pulsar.zsh"
      current_id="unknown"
      ;;
    *)
      echo "Unknown update channel '$_chan'; using main branch"
      branch_or_tag=main
      url="https://raw.githubusercontent.com/${PULSAR_REPO:-astrosteveo/pulsar}/main/pulsar.zsh"
      current_id="unknown"
      ;;
  esac

  local temp_file=$(mktemp)

  # Download to temp file
  if ! command curl -fsSL -o "$temp_file" "$url"; then
    echo "Failed to download update from $url"
    rm -f "$temp_file"
    return 1
  fi

  # Validate downloaded file
  if [[ $(grep -c "plugin-clone" "$temp_file") -eq 0 ]]; then
    echo "Invalid Pulsar file downloaded (missing core functions)"
    rm -f "$temp_file"
    return 1
  fi

  # Determine new version/commit
  if [[ "$_chan" == "stable" ]]; then
    new_id=$(pulsar__extract_version "$temp_file" 2>/dev/null || echo "unknown")
  elif [[ "$_chan" == "unstable" ]]; then
    new_id=$(pulsar__get_main_sha 2>/dev/null)
    [[ -n "$new_id" ]] && new_id="${new_id[1,7]}" || new_id="latest"
  else
    new_id="unknown"
  fi

  # Show what we're working with
  if [[ "$_chan" == "stable" ]]; then
    echo "Current version: $current_id"
    echo "New version: $new_id"
    # Skip update if versions match
    if [[ "$current_id" != "unknown" && "$new_id" != "unknown" && "$current_id" == "$new_id" ]]; then
      echo "Already at latest version, no update needed"
      rm -f "$temp_file"
      return 0
    fi
  else
    echo "Updating to: $new_id"
  fi

  # If the current file is missing, we're doing a fresh install
  if [[ ! -f "$dest" ]]; then
    echo "Installing Pulsar for the first time"
  fi  # Copy the new version to the destination
  if ! mkdir -p "$(dirname "$dest")" || ! cp "$temp_file" "$dest"; then
    echo "Failed to install update to $dest"
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"

  # Update state file so we don't keep notifying about this version/commit
  pulsar__read_state
  if [[ "$_chan" == "stable" && "$new_id" != "unknown" ]]; then
    _pstate[last_seen_stable_tag]="$new_id"
  elif [[ "$_chan" == "unstable" ]]; then
    # Store the full SHA for unstable channel
    local full_sha
    full_sha=$(pulsar__get_main_sha 2>/dev/null)
    [[ -n "$full_sha" ]] && _pstate[last_seen_unstable_sha]="$full_sha"
  fi
  pulsar__write_state

  # Success message
  if command -v tput >/dev/null 2>&1; then
    if [[ "$current_id" != "unknown" && "$new_id" != "unknown" && "$_chan" == "stable" ]]; then
      printf "%sSuccessfully updated Pulsar from %s to %s (stable)%s\n" "$(tput setaf 2)" "$current_id" "$new_id" "$(tput sgr0)"
    elif [[ "$_chan" == "unstable" ]]; then
      printf "%sSuccessfully updated Pulsar to commit %s (unstable)%s\n" "$(tput setaf 2)" "$new_id" "$(tput sgr0)"
    else
      printf "%sSuccessfully updated Pulsar to latest version%s\n" "$(tput setaf 2)" "$(tput sgr0)"
    fi
  else
    if [[ "$current_id" != "unknown" && "$new_id" != "unknown" && "$_chan" == "stable" ]]; then
      echo "Successfully updated Pulsar from $current_id to $new_id (stable)"
    elif [[ "$_chan" == "unstable" ]]; then
      echo "Successfully updated Pulsar to commit $new_id (unstable)"
    else
      echo "Successfully updated Pulsar to latest version"
    fi
  fi

  echo "Reloading Pulsar..."

  # Source the new version
  if ! source "$dest" 2>/dev/null; then
    echo "Failed to source updated Pulsar"
    return 1
  fi

  echo "✓ Pulsar self-update complete!"
  return 0
}

##? Update Pulsar and plugins.
function pulsar-update {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  echo "=== Pulsar Self-Update ==="
  if pulsar-self-update; then
    echo "=== Pulsar core update complete ==="
  else
    echo "=== Pulsar core update skipped ==="
  fi

  echo ""
  echo "=== Plugin Updates ==="
  plugin-update
}

##? Migrate user config: optionally replace legacy 'edge' with 'unstable' in the managed pulsar block
function pulsar-migrate-config {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local apply=0 zshrc target start_marker end_marker tmp backup
  while (( $# )); do
    case $1 in
      --apply) apply=1 ;;
      -h|--help) echo "Usage: pulsar-migrate-config [--apply]"; return 0 ;;
      *) echo "Invalid option $1"; return 2 ;;
    esac
    shift
  done
  # Find the managed pulsar block location like the installer
  if [[ -n ${ZDOTDIR-} && $ZDOTDIR != $HOME ]]; then
    zshrc=${ZDOTDIR}/.zshrc
  else
    zshrc=$HOME/.zshrc
  fi
  start_marker="# >>> pulsar >>>"
  end_marker="# <<< pulsar <<<"
  if [[ ! -f $zshrc ]]; then
    echo "No $zshrc found"; return 0
  fi
  tmp=$(mktemp)
  # Extract current block and show diff of proposed change
  sed -n "/^${start_marker}\$/,/^${end_marker}\$/p" "$zshrc" > "$tmp.block" 2>/dev/null || true
  if ! grep -q "PULSAR_UPDATE_CHANNEL=.*edge" "$tmp.block" 2>/dev/null; then
    echo "No legacy 'edge' setting found in pulsar block in $zshrc"; rm -f "$tmp.block"; return 0
  fi
  echo "Found legacy 'edge' in pulsar block at $zshrc"
  echo "Proposed change: replace PULSAR_UPDATE_CHANNEL=...edge with PULSAR_UPDATE_CHANNEL=unstable"
  if (( apply )); then
    backup="$zshrc.pulsar.migrate.bak.$(date -u +%Y%m%d%H%M%S)"
    cp -- "$zshrc" "$backup" 2>/dev/null || cp "$zshrc" "$backup"
    # perform replacement only inside the block
    awk -v start="$start_marker" -v end="$end_marker" '
      { print_line = 1 }
      $0 == start { inblock=1; print_line=1 }
      inblock && /PULSAR_UPDATE_CHANNEL=.*edge/ { sub(/edge/,"unstable") }
      { print }
      $0 == end { inblock=0 }
    ' "$zshrc" > "$tmp" && mv -f "$tmp" "$zshrc"
    echo "Applied change to $zshrc (backup at $backup)"
  else
    echo "Run 'pulsar-migrate-config --apply' to modify $zshrc (backup will be created)."
  fi
  rm -f "$tmp.block" 2>/dev/null || true
}

##? Benchmark helper: runs multiple iterations and reports mean/median startup time
function pulsar-benchmark {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local file=${1:-"$ZSH/lib/pulsar.zsh"}
  local iterations=${2:-10}
  if [[ ! -f $file ]]; then echo "Benchmark target not found: $file"; return 1; fi

  echo "Benchmarking $file (${iterations} iterations)..."
  local -a times
  local i start end elapsed_ms

  for (( i=1; i<=iterations; i++ )); do
    start=$(date +%s%3N 2>/dev/null || date +%s000)
    ZDOTDIR=$ZDOTDIR HOME=$HOME zsh -fc "source $file" >/dev/null 2>&1 || true
    end=$(date +%s%3N 2>/dev/null || date +%s000)
    elapsed_ms=$((end - start))
    times+=($elapsed_ms)
    printf "."
  done
  echo ""

  # Calculate statistics
  local sum=0 min=${times[1]} max=${times[1]}
  for elapsed_ms in $times; do
    (( sum += elapsed_ms ))
    (( elapsed_ms < min )) && min=$elapsed_ms
    (( elapsed_ms > max )) && max=$elapsed_ms
  done
  local mean=$((sum / iterations))

  # Calculate median
  local -a sorted
  sorted=(${(n)times})  # numeric sort
  local median
  if (( iterations % 2 == 1 )); then
    median=${sorted[$(( (iterations + 1) / 2 ))]}
  else
    local mid1=${sorted[$(( iterations / 2 ))]}
    local mid2=${sorted[$(( iterations / 2 + 1 ))]}
    median=$(( (mid1 + mid2) / 2 ))
  fi

  # Report results
  printf "\nResults for %s:\n" "$file"
  printf "  Iterations: %d\n" "$iterations"
  printf "  Mean:       %d ms\n" "$mean"
  printf "  Median:     %d ms\n" "$median"
  printf "  Min:        %d ms\n" "$min"
  printf "  Max:        %d ms\n" "$max"
}

# Trigger update check after all functions are loaded
if (( PULSAR_UPDATE_NOTIFY )); then
  pulsar__check_update
fi
