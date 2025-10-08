# Pulsar - Oh-My-Zsh Migration Example
# ======================================
#
# This example shows how to migrate from oh-my-zsh to Pulsar while keeping
# your favorite OMZ plugins working.

# ============================================================================
# Step 1: Remove Oh-My-Zsh
# ============================================================================
#
# Before: Your .zshrc probably had something like this:
#
#   export ZSH="$HOME/.oh-my-zsh"
#   ZSH_THEME="robbyrussell"
#   plugins=(git docker kubectl)
#   source $ZSH/oh-my-zsh.sh
#
# Remove those lines (or comment them out) before proceeding.

# ============================================================================
# Step 2: Load Pulsar
# ============================================================================

source ~/.local/share/zsh/pulsar.zsh  # Or wherever you installed it

# ============================================================================
# Step 3: Migrate Your Plugins
# ============================================================================

# Old OMZ plugin configuration:
# plugins=(
#   git
#   docker
#   kubectl
#   systemd
#   common-aliases
# )

# New Pulsar configuration (using subdirectory syntax):
PULSAR_PLUGINS=(
  # OMZ plugins - no need to install oh-my-zsh!
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
  ohmyzsh/ohmyzsh/plugins/systemd
  ohmyzsh/ohmyzsh/plugins/common-aliases

  # Bonus: Add non-OMZ plugins easily
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# ============================================================================
# Step 4: Migrate Your Theme
# ============================================================================

# Old OMZ theme configuration:
# ZSH_THEME="robbyrussell"

# Option A: Use a popular prompt theme
PULSAR_PLUGINS+=(
  romkatv/powerlevel10k  # Modern, fast, feature-rich
  # or
  # sindresorhus/pure  # Minimal, elegant
)

# Option B: Keep using OMZ theme
# PULSAR_PLUGINS+=(
#   ohmyzsh/ohmyzsh/themes/robbyrussell
# )

# ============================================================================
# Step 5: Load Everything
# ============================================================================

plugin-load

# ============================================================================
# Common OMZ Plugins Mapped to Pulsar
# ============================================================================

# git → ohmyzsh/ohmyzsh/plugins/git
# docker → ohmyzsh/ohmyzsh/plugins/docker
# kubectl → ohmyzsh/ohmyzsh/plugins/kubectl
# npm → ohmyzsh/ohmyzsh/plugins/npm
# nvm → ohmyzsh/ohmyzsh/plugins/nvm
# rust → ohmyzsh/ohmyzsh/plugins/rust
# python → ohmyzsh/ohmyzsh/plugins/python
# systemd → ohmyzsh/ohmyzsh/plugins/systemd
# tmux → ohmyzsh/ohmyzsh/plugins/tmux
# vi-mode → ohmyzsh/ohmyzsh/plugins/vi-mode

# Just prefix with: ohmyzsh/ohmyzsh/plugins/

# ============================================================================
# What You Gain
# ============================================================================
#
# ✓ Faster shell startup (no OMZ overhead)
# ✓ Cleaner configuration (no ~/.oh-my-zsh directory)
# ✓ Parallel plugin cloning
# ✓ Easy to add non-OMZ plugins
# ✓ Better plugin management (update, compile, etc.)
# ✓ Minimal codebase (<1000 lines vs. OMZ's thousands)
#
# What You Lose
# ============================================================================
#
# ✗ OMZ's helper functions (mostly aliases, which you can replicate)
# ✗ OMZ's update mechanism (but Pulsar has its own: pulsar-update)
# ✗ OMZ's custom themes (but you can still use them via subdirectory syntax)
#
# ============================================================================
# Optional: Clean Up
# ============================================================================
#
# After verifying everything works, you can remove OMZ:
#
#   rm -rf ~/.oh-my-zsh
#
# Pulsar clones only the plugins you need to its own cache directory.

# ============================================================================
# Troubleshooting
# ============================================================================

# If a plugin doesn't work:
# 1. Check if it's loading:
#    pulsar-check-conflicts

# 2. Enable debug mode:
#    export PULSAR_DEBUG=1
#    plugin-load ohmyzsh/ohmyzsh/plugins/git

# 3. Check the OMZ plugin's README for dependencies
#    Some OMZ plugins require additional tools (e.g., kubectl plugin needs kubectl)

# 4. Force re-clone if cache is corrupted:
#    plugin-clone --force ohmyzsh/ohmyzsh/plugins/git
