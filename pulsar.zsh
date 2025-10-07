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

##? Clone zsh plugins in parallel.
function plugin-clone {
  emulate -L zsh; setopt local_options $_pulsar_zopts
  local repo plugdir; local -Ua repos

  # Remove bare words ${(M)@:#*/*} and paths with leading slash ${@:#/*}.
  # Then split/join to keep the 2-part user/repo form to bulk-clone repos.
  for repo in ${${(M)@:#*/*}:#/*}; do
    repo=${(@j:/:)${(@s:/:)repo}[1,2]}
    [[ -e $PULSAR_HOME/$repo ]] || repos+=$repo
  done

  for repo in $repos; do
    plugdir=$PULSAR_HOME/$repo
    if [[ ! -d $plugdir ]]; then
      echo "Cloning $repo..."
      (
        command git clone -q --depth 1 --recursive --shallow-submodules \
          ${PULSAR_GITURL:-https://github.com/}$repo $plugdir
        plugin-compile $plugdir
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
      echo "$kind=(\$$kind $PULSAR_HOME/$plugin)"
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
