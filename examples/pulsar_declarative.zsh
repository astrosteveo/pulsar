# Pulsar declarative example

# Setup vars
ZSH=${ZSH:-${ZDOTDIR:-$HOME/.config/zsh}}

# Download Pulsar if needed
if [[ ! -e $ZSH/lib/pulsar.zsh ]]; then
  mkdir -p $ZSH/lib
  curl -fsSL -o $ZSH/lib/pulsar.zsh \
    https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh
fi

# Declarative config
PULSAR_PATH=(romkatv/zsh-bench)
PULSAR_FPATH=(sindresorhus/pure)
PULSAR_PLUGINS=(
  zsh-users/zsh-completions
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
PULSAR_AUTOCOMPILE=1

# Load Pulsar (auto clones/loads)
source $ZSH/lib/pulsar.zsh

# Prompt
autoload -U promptinit; promptinit
prompt pure
