# test-omz-plugins

Test Oh-My-Zsh plugin handling and shorthand aliases.

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test shorthand expansion

pulsar sources successfully

```zsh
% source pulsar.zsh #=> --exit 0
% echo $+functions[pulsar__expand_shorthand]
1
%
```

OMZP:: expands to ohmyzsh/ohmyzsh/plugins/

```zsh
% pulsar__expand_shorthand "OMZP::git"
ohmyzsh/ohmyzsh/plugins/git
%
```

OMZL:: expands to ohmyzsh/ohmyzsh/lib/

```zsh
% pulsar__expand_shorthand "OMZL::completion"
ohmyzsh/ohmyzsh/lib/completion
%
```

OMZT:: expands to ohmyzsh/ohmyzsh/themes/

```zsh
% pulsar__expand_shorthand "OMZT::robbyrussell"
ohmyzsh/ohmyzsh/themes/robbyrussell
%
```

Non-shorthand specs pass through unchanged

```zsh
% pulsar__expand_shorthand "ohmyzsh/ohmyzsh/plugins/git"
ohmyzsh/ohmyzsh/plugins/git
% pulsar__expand_shorthand "zsh-users/zsh-syntax-highlighting"
zsh-users/zsh-syntax-highlighting
%
```

## Test OMZ plugin cloning message

OMZ plugins show full spec in cloning message

```zsh
% plugin-clone ohmyzsh/ohmyzsh/plugins/git 2>&1 | grep -o "Cloning.*"
Cloning ohmyzsh/ohmyzsh/plugins/git...
%
```

Shorthand shows full expanded spec in cloning message

```zsh
% plugin-clone OMZP::docker 2>&1 | grep -o "Cloning.*"
Cloning OMZP::docker...
%
```

## Teardown

```zsh
% t_teardown
%
```
