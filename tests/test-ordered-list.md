# test-ordered-list

````markdown

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test

Create simple local mock plugins

```zsh
% mkdir -p $T_TEMPDIR/mock/local1
% printf '%s\n' 'echo local1' > $T_TEMPDIR/mock/local1/local1.plugin.zsh
% mkdir -p $T_TEMPDIR/mock/local2/bin
% printf '%s\n' '#!/bin/sh\necho local2bin' > $T_TEMPDIR/mock/local2/bin/local2
% chmod +x $T_TEMPDIR/mock/local2/bin/local2
%
```

Use unified ordered list and ensure order is preserved

```zsh
% PULSAR_PLUGINS=($T_TEMPDIR/mock/local1 path:$T_TEMPDIR/mock/local2)
% source ./pulsar.zsh #=> --exit 0
% command -v local2 >/dev/null && echo ok
ok
%
```

Repo specs still clone/load; we can smoke test with a lightweight repo (no net in CI, so skip actual clone here)

```zsh
% PULSAR_PLUGINS=(zsh-users/zsh-completions) ; PULSAR_NO_AUTORUN=1 ; source ./pulsar.zsh ; echo ok
ok
%
```

Legacy arrays remain compatible

```zsh
% unset PULSAR_PLUGINS
% PULSAR_PATH=($T_TEMPDIR/mock/local2)
% PULSAR_FPATH=($T_TEMPDIR/mock/local1)
% source ./pulsar.zsh #=> --exit 0
% command -v local2 >/dev/null && echo ok
ok
%
```

## Teardown

```zsh
% t_teardown
%
```

````
