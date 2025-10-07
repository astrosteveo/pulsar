# Pulsar - a micro zsh plugin manager inspired by antidote and zsh_unplugged.
# author:  mattmc3 (adapted for Pulsar)
# home:    https://github.com/mattmc3/zsh_unplugged
# license: https://unlicense.org
# usage:   plugin-load $myplugins
# version: 0.1.0

# Set variables.
: ${PULSAR_HOME:=${XDG_CACHE_HOME:-~/.cache}/pulsar}
: ${ZPLUGINDIR:=${ZSH_CUSTOM:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}/plugins}
typeset -gHa _pulsar_zopts=(extended_glob glob_dots no_monitor)
typeset -g PULSAR_FORCE_RECLONE=${PULSAR_FORCE_RECLONE:-}

##? Clone zsh plugins in parallel.
function plugin-clone {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local spec repo ref plugdir; local -A refmap; local -Ua allrepos repos

  # Ensure base directory exists
  [[ -d $PULSAR_HOME ]] || command mkdir -p -- $PULSAR_HOME

  # Remove bare words ${(M)@:#*/*} and paths with leading slash ${@:#/*}.
  # Then split/join to keep the 2-part user/repo form to bulk-clone repos.
  for spec in ${${(M)@:#*/*}:#/*}; do
    ref=${spec##*@}
    repo=${spec%@*}
    repo=${(@j:/:)${(@s:/:)repo}[1,2]}
    allrepos+=$repo
    # store ref only if actually provided with '@'
    if [[ $spec == *"@"* || ${spec#*@} != $spec ]]; then
      refmap[$repo]=$ref
    fi
    if [[ -e $PULSAR_HOME/$repo ]]; then
      if [[ -n $PULSAR_FORCE_RECLONE ]]; then
        command rm -rf -- $PULSAR_HOME/$repo
        repos+=$repo
      fi
    else
      repos+=$repo
    fi
  done

  for repo in $repos; do
    plugdir=$PULSAR_HOME/$repo
    if [[ ! -d $plugdir ]]; then
      echo "Cloning $repo..."
      (
        command mkdir -p -- ${plugdir:h}
        command git clone -q --depth 1 --recursive --shallow-submodules \
          ${PULSAR_GITURL:-https://github.com/}$repo $plugdir || return
        # If a ref was provided for this repo, fetch and checkout it
        if [[ -n ${refmap[$repo]-} ]]; then
          local _ref=${refmap[$repo]}
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
  fi
}
