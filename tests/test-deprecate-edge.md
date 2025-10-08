`````markdown
````markdown
# test-deprecate-edge

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test

Auto-migrate legacy 'edge' channel at v1.0.0 (mocked)

```zsh
% export TEST_HOME=$T_TEMPDIR/home-migrate
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache-migrate
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=edge PULSAR_UPDATE_CHECK_INTERVAL=0
% export PULSAR_VERSION=v1.0.0
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh' | grep -q "Auto-migrating update channel from 'edge' to 'unstable'" && echo ok
ok
% test -f $XDG_CACHE_HOME/pulsar/update_state && grep -q update_channel_migrated_from_edge $XDG_CACHE_HOME/pulsar/update_state && echo ok
ok
%
```

## Teardown

```zsh
% t_teardown
%
```

````

`````
