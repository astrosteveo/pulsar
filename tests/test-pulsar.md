# test-pulsar

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test

plugin-load function does not exist

```zsh
% echo $+functions[plugin-load]
0
%
```

pulsar sources successfully

```zsh
% source pulsar.zsh #=> --exit 0
% echo $+functions[plugin-load]
1
% echo $+functions[plugin-clone]
1
% echo $+functions[plugin-update]
1
% echo $+functions[plugin-compile]
1
%
```

pulsar clones and loads a plugin

```zsh
% echo $+functions[zsh-defer]
0
% plugin-clone romkatv/zsh-defer
Cloning romkatv/zsh-defer...
% plugin-load romkatv/zsh-defer
% echo $+functions[zsh-defer]
1
%
```

pulsar sets PULSAR_HOME correctly

```zsh
% echo $PULSAR_HOME | substenv XDG_CACHE_HOME
$XDG_CACHE_HOME/pulsar
%
```

## Teardown

```zsh
% t_teardown
%
```
