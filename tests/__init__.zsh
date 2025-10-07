#!/bin/zsh
# Force predictable test output: progress on, no color, suppress updater noise
export PULSAR_PROGRESS=1
export PULSAR_COLOR=0
export PULSAR_UPDATE_NOTIFY=0
export PULSAR_UPDATE_CHANNEL=stable

function t_setup {
  emulate -L zsh
  setopt local_options null_glob
  0=${(%):-%x}

  # save fpath
  typeset -g T_PREV_FPATH=( $fpath )

  # mock git
  # function git { echo git "$@" }

  # works with BSD and GNU gmktemp
  T_TEMPDIR=${$(mktemp -d -t pulsar.XXXXXXXX):A}

  # put zdotdir in position
  mkdir -p $T_TEMPDIR/plugins
  typeset -g OLD_ZDOTDIR=$ZDOTDIR
  export ZDOTDIR=$T_TEMPDIR/zdotdir
  typeset -g OLD_XDG_DATA_HOME=$XDG_DATA_HOME
  export XDG_DATA_HOME=$T_TEMPDIR/.local/share
  typeset -g OLD_XDG_CACHE_HOME=$XDG_CACHE_HOME
  export XDG_CACHE_HOME=$T_TEMPDIR/.cache

}

function t_teardown {
  emulate -L zsh
  setopt local_options
  0=${(%):-%x}

  # reset current session
  export ZDOTDIR=$OLD_ZDOTDIR
  export XDG_DATA_HOME=$OLD_XDG_DATA_HOME
  export XDG_CACHE_HOME=$OLD_XDG_CACHE_HOME
  unset ZPLUGINDIR

  # restore original fpath
  fpath=( $T_PREV_FPATH )

  # unfunction
  for funcname in clone load compile update; do
    (( $+functions[plugin-$funcname] )) && unfunction plugin-${funcname}
  done
  for funcname in zsh-defer; do
    (( $+functions[$funcname] )) && unfunction ${funcname}
  done

  # remove tempdir
  [[ -d "$T_TEMPDIR" ]] && rm -rf -- "$T_TEMPDIR"
}

function substenv {
  if (( $# == 0 )); then
    substenv ZDOTDIR | substenv HOME
  else
    local sedexp="s|${(P)1}|\$$1|g"
    shift
    command sed "$sedexp" "$@"
  fi
}

function mockgit {
}
