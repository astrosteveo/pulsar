#!/usr/bin/env zsh
# Pulsar - Oh-My-Zsh and Prezto Integration Example
# ==================================================
#
# This example demonstrates how to use Oh-My-Zsh and Prezto plugins
# with Pulsar without installing the full frameworks.

# ============================================================================
# Load Pulsar
# ============================================================================

source ~/.local/share/zsh/pulsar.zsh  # Or wherever you installed it

# ============================================================================
# Oh-My-Zsh Plugins
# ============================================================================

PULSAR_PLUGINS=(
  # OMZ Plugins (directories with .plugin.zsh files)
  # Each plugin provides commands, aliases, and functions
  OMZP::git              # Git aliases and functions
  OMZP::docker           # Docker completion and aliases
  OMZP::kubectl          # Kubernetes completion
  OMZP::npm              # npm completion and aliases
  OMZP::colored-man-pages # Colorize man pages
  
  # OMZ Library Files (standalone .zsh files)
  # These are core OMZ utilities
  OMZL::completion       # Completion configuration
  OMZL::key-bindings     # Key bindings
  OMZL::history          # History configuration
  OMZL::directories      # Directory navigation aliases
  
  # OMZ Themes (standalone .zsh-theme files)
  # Note: Modern themes like powerlevel10k are better
  # OMZT::robbyrussell   # Classic OMZ theme
)

# ============================================================================
# Prezto Modules
# ============================================================================

# Uncomment to use Prezto modules instead of or alongside OMZ
# PULSAR_PLUGINS+=(
#   PZT::environment     # Environment setup
#   PZT::editor          # Editor configuration
#   PZT::git             # Git aliases
#   PZT::completion      # Completion system
#   PZT::syntax-highlighting  # Syntax highlighting
# )

# ============================================================================
# Modern Plugins (Mix and Match!)
# ============================================================================

# You can combine OMZ/Prezto with modern standalone plugins
PULSAR_PLUGINS+=(
  # Modern theme (better than OMZ themes)
  romkatv/powerlevel10k
  
  # Essential quality-of-life plugins
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  
  # Useful tools
  # romkatv/zsh-defer  # Defer plugin loading for faster startup
  # junegunn/fzf       # Fuzzy finder
)

# ============================================================================
# Load Everything
# ============================================================================

# Pulsar automatically:
# 1. Clones missing repositories (only owner/repo, not subdirs)
# 2. Detects if subdirs are files or directories
# 3. Finds the correct init file (.plugin.zsh, .zsh, .zsh-theme, init.zsh)
# 4. Initializes completions for OMZ plugins
# 5. Sources all plugins in order

plugin-load

# ============================================================================
# What Happens Behind the Scenes
# ============================================================================

# For OMZP::git:
# 1. Expands to: ohmyzsh/ohmyzsh/plugins/git
# 2. Clones: ohmyzsh/ohmyzsh (if not already cached)
# 3. Detects: plugins/git/ is a directory
# 4. Finds: plugins/git/git.plugin.zsh
# 5. Sources it!

# For OMZL::completion:
# 1. Expands to: ohmyzsh/ohmyzsh/lib/completion
# 2. Uses cached: ohmyzsh/ohmyzsh (already cloned)
# 3. Detects: lib/completion is NOT a directory
# 4. Finds: lib/completion.zsh (direct file)
# 5. Sources it!

# For PZT::git:
# 1. Expands to: sorin-ionescu/prezto/modules/git
# 2. Clones: sorin-ionescu/prezto (if not already cached)
# 3. Detects: modules/git/ is a directory
# 4. Finds: modules/git/init.zsh
# 5. Sources it!

# ============================================================================
# Performance Tips
# ============================================================================

# 1. Auto-compile for faster loading
# export PULSAR_AUTOCOMPILE=1

# 2. Or manually compile once after updates
# plugin-compile

# 3. Use zsh-defer to defer non-essential plugins
# PULSAR_PLUGINS+=(romkatv/zsh-defer)
# This makes subsequent plugins load in the background

# ============================================================================
# Troubleshooting
# ============================================================================

# Check Pulsar status
# pulsar-doctor

# Force re-clone if something is broken
# PULSAR_FORCE_RECLONE=1 plugin-clone OMZP::git

# Update all plugins and Pulsar core
# pulsar-update

# Check what plugins are loaded
# plugin-list  # (if implemented)

# ============================================================================
# Common OMZ Plugins Mapped to Pulsar
# ============================================================================

# git              → OMZP::git
# docker           → OMZP::docker
# kubectl          → OMZP::kubectl
# npm              → OMZP::npm
# nvm              → OMZP::nvm
# rust             → OMZP::rust
# python           → OMZP::python
# systemd          → OMZP::systemd
# tmux             → OMZP::tmux
# vi-mode          → OMZP::vi-mode
# colored-man-pages → OMZP::colored-man-pages
# command-not-found → OMZP::command-not-found

# ============================================================================
# Common Prezto Modules
# ============================================================================

# environment      → PZT::environment
# editor           → PZT::editor
# git              → PZT::git
# completion       → PZT::completion
# syntax-highlighting → PZT::syntax-highlighting
# history-substring-search → PZT::history-substring-search
# autosuggestions  → PZT::autosuggestions

# ============================================================================
# Benefits Over Full OMZ/Prezto Installation
# ============================================================================

# ✅ Faster shell startup (no framework overhead)
# ✅ Cleaner configuration (just a list of plugins)
# ✅ Smaller disk footprint (only clone what you need)
# ✅ Easier to understand (no hidden magic)
# ✅ Mix and match from different sources
# ✅ Better plugin management (update, compile, etc.)
# ✅ Minimal codebase (<1000 lines vs. OMZ's thousands)

# ============================================================================
# Migration Notes
# ============================================================================

# From Oh-My-Zsh:
# 1. Replace: plugins=(git docker) 
#    With: PULSAR_PLUGINS=(OMZP::git OMZP::docker)
# 2. Remove: source $ZSH/oh-my-zsh.sh
#    Add: source ~/.local/share/zsh/pulsar.zsh
# 3. Remove: export ZSH="$HOME/.oh-my-zsh"
# 4. Optional: rm -rf ~/.oh-my-zsh (after verifying everything works)

# From Prezto:
# 1. Replace: zstyle ':prezto:load' pmodule 'git' 'completion'
#    With: PULSAR_PLUGINS=(PZT::git PZT::completion)
# 2. Remove: source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
#    Add: source ~/.local/share/zsh/pulsar.zsh
# 3. Optional: rm -rf ~/.zprezto (after verifying everything works)
