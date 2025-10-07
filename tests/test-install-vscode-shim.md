# test-install-vscode-shim

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test

Create temp HOME and run installer

```zsh
% export TEST_HOME=$T_TEMPDIR/home
% mkdir -p $TEST_HOME
% HOME=$TEST_HOME XDG_CONFIG_HOME=$T_TEMPDIR/.config sh ./install.sh #=> --exit 0
%
```

Ensure ZDOTDIR and files are created

```zsh
% echo ${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh} | substenv ZDOTDIR | substenv XDG_CONFIG_HOME | substenv HOME
$ZDOTDIR
% test -f $TEST_HOME/.zshenv && grep -q 'export ZDOTDIR=' $TEST_HOME/.zshenv && echo ok
ok
% test -f $ZDOTDIR/.zshrc && echo ok
ok
% test -f $ZDOTDIR/lib/pulsar-bootstrap.zsh && echo ok
ok
%
```

Verify VS Code shim exists in ~/.zshrc and sources $ZDOTDIR/.zshrc when TERM_PROGRAM=vscode

```zsh
% test -f $TEST_HOME/.zshrc && grep -q 'pulsar-zdotdir-shim' $TEST_HOME/.zshrc && echo ok
ok
% TERM_PROGRAM=vscode HOME=$TEST_HOME ZDOTDIR=$ZDOTDIR zsh -fc 'source ~/.zshrc; echo sourced' #=> --stdout "sourced"
%
```

Re-run installer to confirm idempotency (no duplicate blocks)

```zsh
% HOME=$TEST_HOME XDG_CONFIG_HOME=$T_TEMPDIR/.config sh ./install.sh #=> --exit 0
% grep -c '^# >>> pulsar >>>' $ZDOTDIR/.zshrc
1
% grep -c '^# >>> pulsar-zdotdir-shim >>>' $TEST_HOME/.zshrc
1
%
```

## Teardown

```zsh
% t_teardown
%
```
