````markdown
# test-updater

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test

Force stable channel notifier when a newer tag exists (mocked)

```zsh
% export TEST_HOME=$T_TEMPDIR/home
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=stable PULSAR_UPDATE_CHECK_INTERVAL=0
% export PULSAR_VERSION=v0.3.0
% function pulsar__get_latest_tag { echo v0.3.1 }
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh' | grep -q "Pulsar update available:" && echo ok
ok
% test -f $XDG_CACHE_HOME/pulsar/update_state && echo ok
ok
%
```

Local version notice fires once per new version

```zsh
% export TEST_HOME=$T_TEMPDIR/home5
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache5
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=off PULSAR_VERSION=v9.9.9
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh' | grep -q "Pulsar updated to v9.9.9" && echo ok
ok
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh' | grep -q "Pulsar updated to v9.9.9" || echo ok
ok
%
```

Force unstable channel notifier when main advances (mocked)

```zsh
% export TEST_HOME=$T_TEMPDIR/home2
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache2
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=unstable PULSAR_UPDATE_CHECK_INTERVAL=0
% function pulsar__get_main_sha { echo deadbeefcafebabe000000000000000000000000 }
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh' | grep -q "Pulsar update available on main" && echo ok
ok
% test -f $XDG_CACHE_HOME/pulsar/update_state && echo ok
ok
%
```

No notifier when channel is off

```zsh
% export TEST_HOME=$T_TEMPDIR/home3
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache3
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=off PULSAR_UPDATE_CHECK_INTERVAL=0
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh; echo done' | grep -q "Pulsar update available" || echo ok
ok
%
```

Interval gating prevents frequent checks

```zsh
% export TEST_HOME=$T_TEMPDIR/home4
% mkdir -p $TEST_HOME
% export XDG_CACHE_HOME=$T_TEMPDIR/.cache4
% export PULSAR_UPDATE_NOTIFY=1 PULSAR_UPDATE_CHANNEL=stable PULSAR_UPDATE_CHECK_INTERVAL=999999
% mkdir -p $XDG_CACHE_HOME/pulsar
% echo last_check_epoch=$(date +%s) > $XDG_CACHE_HOME/pulsar/update_state
% function pulsar__get_latest_tag { echo v999.999.999 }
% ZDOTDIR=$ZDOTDIR HOME=$TEST_HOME zsh -fc 'source ./pulsar.zsh; echo done' | grep -q "Pulsar update available" || echo ok
ok
%
```

## Teardown

```zsh
% t_teardown
%
```

````
