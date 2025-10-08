# Quickstart Guide: Pulsar Plugin Manager

**Feature**: Pulsar - Minimal Zsh Plugin Manager
**Date**: 2025-10-07
**Purpose**: Common usage scenarios and integration examples

## Overview

This guide provides practical examples for common Pulsar usage scenarios, helping users get started quickly and understand integration patterns.

---

## Scenario 1: Fresh Installation (New User)

**Goal**: Install Pulsar and start using plugins immediately

### Installation Command

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/user/pulsar/main/install.sh)"
```

### What Happens

1. Installer downloads `pulsar.zsh` to a standard location
2. Creates backup: `~/.zshrc.backup.YYYYMMDD-HHMMSS`
3. Adds Pulsar configuration block to `~/.zshrc`
4. Reports success and next steps

### Default Configuration Block

```zsh
# ===== Pulsar Plugin Manager =====
# Added by Pulsar installer on 2025-10-07

# Load Pulsar
source ~/.local/share/pulsar/pulsar.zsh

# Configure plugins (examples)
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# Load plugins
plugin-load

# Optional: Auto-update settings
PULSAR_UPDATE_CHANNEL=stable  # or 'unstable', 'off'
```

### Next Steps

```bash
# Restart shell to activate
exec zsh

# First startup: plugins are cloned automatically
# Subsequent startups: plugins loaded from cache (fast)
```

### Expected Output

```text
[pulsar] Cloning romkatv/powerlevel10k...
[pulsar] Cloning zsh-users/zsh-syntax-highlighting...
[pulsar] Cloning zsh-users/zsh-autosuggestions...
[pulsar] ✓ 3 plugins loaded successfully in 4.2s
```

---

## Scenario 2: Using Oh-My-Zsh Plugins (Without OMZ)

**Goal**: Use OMZ plugins without installing Oh-My-Zsh

### Configuration

```zsh
# In ~/.zshrc

PULSAR_PLUGINS=(
  # Use OMZ plugins with subdirectory syntax
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
  ohmyzsh/ohmyzsh/plugins/npm

  # Or use convenient shorthand aliases
  OMZP::git         # Same as ohmyzsh/ohmyzsh/plugins/git
  OMZP::docker      # Same as ohmyzsh/ohmyzsh/plugins/docker
  OMZL::completion  # Same as ohmyzsh/ohmyzsh/lib/completion

  # Mix with regular plugins
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

plugin-load
```

### How It Works

1. Pulsar clones full `ohmyzsh/ohmyzsh` repository once
2. Loads specific plugin from subdirectory (`plugins/git`)
3. Multiple OMZ plugins reuse single clone (efficient)
4. No OMZ framework overhead

### Cache Structure

```text
$PULSAR_HOME/
└── ohmyzsh--ohmyzsh/            # Cloned once
    └── plugins/
        ├── git/                 # Loaded
        ├── docker/              # Loaded
        ├── kubectl/             # Loaded
        └── npm/                 # Loaded
```

### Expected Behavior

```bash
# First startup
[pulsar] Cloning ohmyzsh/ohmyzsh...
[pulsar] ✓ Loading git plugin from ohmyzsh/ohmyzsh/plugins/git
[pulsar] ✓ Loading docker plugin from ohmyzsh/ohmyzsh/plugins/docker
[pulsar] ✓ 6 plugins loaded successfully in 5.1s

# Subsequent startups (cached)
[pulsar] ✓ 6 plugins loaded in 0.04s
```

---

## Scenario 3: Adding Command-Line Tools to PATH

**Goal**: Install tools like `fzf`, `fd`, `bat` without manual PATH setup

### Configuration

```zsh
# In ~/.zshrc

# Traditional plugins (sourced)
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
)

# Tools added to PATH (not sourced)
PULSAR_PATH=(
  junegunn/fzf
  sharkdp/fd
  sharkdp/bat
)

# Load both
plugin-load
```

### How It Works

1. `PULSAR_PATH` plugins are cloned like regular plugins
2. Their `bin/` directory is added to `$PATH`
3. No sourcing occurs (just PATH modification)
4. Tools become available as commands

### Usage Example

```bash
# After loading with PULSAR_PATH
$ fzf --version
0.42.0

$ fd --version
fd 8.7.0

$ bat --version
bat 0.23.0
```

### Mixed Loading Modes

```zsh
# Some plugins sourced, some added to PATH
PULSAR_PLUGINS=(zsh-users/zsh-syntax-highlighting)  # Sourced
PULSAR_PATH=(junegunn/fzf)                          # PATH only
PULSAR_FPATH=(zsh-users/zsh-completions)            # fpath only

# All loaded with one command
plugin-load
```

---

## Scenario 4: Custom ZDOTDIR Setup

**Goal**: Use Pulsar with non-standard Zsh configuration directory

### Directory Structure

```text
$HOME/
├── .zshenv                      # Sets ZDOTDIR
└── .config/zsh/                 # Custom ZDOTDIR
    ├── .zshrc                   # Main config
    └── lib/
        └── pulsar-bootstrap.zsh # Pulsar config
```

### Configuration Files

**~/.zshenv**:

```zsh
# Set custom ZDOTDIR
export ZDOTDIR=$HOME/.config/zsh
```

**~/.config/zsh/.zshrc**:

```zsh
# Source Pulsar bootstrap
source $ZDOTDIR/lib/pulsar-bootstrap.zsh

# Rest of configuration
```

**~/.config/zsh/lib/pulsar-bootstrap.zsh**:

```zsh
# Load Pulsar
source ~/.local/share/pulsar/pulsar.zsh

# Configure plugins
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# Load plugins
plugin-load
```

### Installation with ZDOTDIR

```bash
# Install Pulsar (detects ZDOTDIR)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/user/pulsar/main/install.sh)"

# Installer will:
# 1. Detect ZDOTDIR from environment
# 2. Backup $ZDOTDIR/.zshrc (not ~/.zshrc)
# 3. Add Pulsar block to $ZDOTDIR/.zshrc
```

---

## Scenario 5: Version Pinning for Stability

**Goal**: Pin specific plugin versions to avoid breaking changes

### Configuration

```zsh
# In ~/.zshrc

PULSAR_PLUGINS=(
  # Pin to specific tag
  romkatv/powerlevel10k@v1.19.0

  # Pin to specific commit
  zsh-users/zsh-syntax-highlighting@cf7f8e2

  # Pin to specific branch
  zsh-users/zsh-autosuggestions@develop

  # No pin (use default branch - usually main/master)
  ohmyzsh/ohmyzsh/plugins/git
)

plugin-load
```

### How It Works

1. Pulsar parses `@version` suffix from plugin spec
2. During clone, checks out specified ref
3. Updates respect version pins (won't auto-update pinned plugins)

### Update Behavior

```bash
# Update all plugins
$ pulsar-update

[pulsar] Updating plugins...
[pulsar] ✓ zsh-users/zsh-autosuggestions (develop): up to date
[pulsar] ✓ ohmyzsh/ohmyzsh: updated to latest
[pulsar] ℹ romkatv/powerlevel10k: pinned to v1.19.0 (skipped)
[pulsar] ℹ zsh-users/zsh-syntax-highlighting: pinned to cf7f8e2 (skipped)
[pulsar] ✓ 2 plugins updated, 2 pinned
```

---

## Scenario 6: Local Plugin Development

**Goal**: Develop and test plugins locally before publishing

### Configuration

```zsh
# In ~/.zshrc

PULSAR_PLUGINS=(
  # Local plugin (absolute path)
  /home/user/projects/my-plugin

  # Published plugins
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

plugin-load
```

### How It Works

1. Pulsar detects local path (starts with `/` or `./` or `~/`)
2. Uses plugin directly from specified path
3. No cloning occurs
4. Changes take effect on next shell restart

### Development Workflow

```bash
# 1. Develop plugin
cd ~/projects/my-plugin
vim my-plugin.zsh

# 2. Test in new shell
exec zsh

# 3. Iterate
vim my-plugin.zsh
exec zsh

# 4. Publish when ready
git push origin main

# 5. Switch to published version
# Edit ~/.zshrc: change /home/user/projects/my-plugin to user/my-plugin
exec zsh
```

---

## Scenario 7: Migrating from Oh-My-Zsh

**Goal**: Migrate existing OMZ configuration to Pulsar

### Before (Oh-My-Zsh)

```zsh
# ~/.zshrc with Oh-My-Zsh

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  docker
  kubectl
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh
```

### After (Pulsar)

```zsh
# ~/.zshrc with Pulsar

# Load Pulsar
source ~/.local/share/pulsar/pulsar.zsh

# Configure plugins
PULSAR_PLUGINS=(
  # Theme (different loading pattern)
  romkatv/powerlevel10k

  # OMZ plugins (with subdirectory syntax)
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl

  # Third-party plugins (direct)
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# Load plugins
plugin-load
```

### Migration Steps

1. **Backup current setup**: `cp ~/.zshrc ~/.zshrc.backup.omz`
2. **Remove OMZ**: `rm -rf ~/.oh-my-zsh` (optional, can keep for reference)
3. **Install Pulsar**: `sh -c "$(curl -fsSL ...)"`
4. **Map plugins**: Convert OMZ plugin names to Pulsar format
5. **Test**: `exec zsh`
6. **Cleanup**: Remove OMZ after verifying everything works

### Plugin Mapping Guide

| OMZ Plugin | Pulsar Equivalent |
|------------|-------------------|
| `git` | `ohmyzsh/ohmyzsh/plugins/git` |
| `docker` | `ohmyzsh/ohmyzsh/plugins/docker` |
| `kubectl` | `ohmyzsh/ohmyzsh/plugins/kubectl` |
| Custom OMZ plugins | `ohmyzsh/ohmyzsh/plugins/{name}` |
| Third-party (not in OMZ) | `{owner}/{repo}` |

---

## Scenario 8: Manual Plugin Control (Advanced)

**Goal**: Manually clone, load, and update plugins for fine-grained control

### Manual Operations

```zsh
# Clone plugin without loading
plugin-clone user/repo

# Load previously cloned plugin
plugin-load-manual user/repo

# Update specific plugin
plugin-update user/repo

# Update all plugins
plugin-update

# Compile all plugins for performance
plugin-compile

# Check for conflicts
pulsar-check-conflicts
```

### Use Cases

**Conditional Loading**:

```zsh
# Load different plugins based on environment
if [[ $OSTYPE == darwin* ]]; then
  plugin-clone mac-specific/plugin
  plugin-load-manual mac-specific/plugin
else
  plugin-clone linux-specific/plugin
  plugin-load-manual linux-specific/plugin
fi
```

**Lazy Loading**:

```zsh
# Load heavy plugin only when needed
function use-kubernetes() {
  plugin-load-manual kubectl-plugin
  kubectl "$@"
}
```

**Troubleshooting**:

```zsh
# Load plugins one at a time to isolate issues
for plugin in ${PULSAR_PLUGINS[@]}; do
  echo "Loading $plugin..."
  plugin-load-manual $plugin || echo "Failed: $plugin"
done
```

---

## Scenario 9: Performance Optimization

**Goal**: Optimize for fastest possible shell startup

### Configuration

```zsh
# In ~/.zshrc

# Disable features you don't need
PULSAR_PROGRESS=0        # No progress bars
PULSAR_BANNER=0          # No startup banner
PULSAR_UPDATE_CHANNEL=off # No auto-update checks

# Load Pulsar
source ~/.local/share/pulsar/pulsar.zsh

# Minimal plugin set
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
)

# Load plugins
plugin-load

# Compile for bytecode speedup (one-time)
plugin-compile
```

### Performance Tuning

```bash
# Measure startup time
time zsh -i -c exit

# Expected: < 0.1s with 5-10 plugins

# Benchmark with zsh-bench
zsh-bench
```

### Tips

1. **Fewer plugins = faster startup**: Only load what you need
2. **Compile scripts**: Run `plugin-compile` after updates
3. **Disable auto-update**: Set `PULSAR_UPDATE_CHANNEL=off` for production
4. **Use lazy loading**: Defer non-critical plugins
5. **Profile startup**: Use `zprof` to identify slow plugins

---

## Scenario 10: Enterprise/Corporate Environment

**Goal**: Use Pulsar in locked-down environment with proxy/firewall

### Configuration

```zsh
# In ~/.zshrc

# Configure Git proxy (if needed)
export https_proxy=http://proxy.corp.com:8080
export http_proxy=http://proxy.corp.com:8080

# Disable auto-updates (corporate policy)
PULSAR_UPDATE_CHANNEL=off

# Load Pulsar
source ~/.local/share/pulsar/pulsar.zsh

# Use only pre-approved plugins
PULSAR_PLUGINS=(
  # Internal mirror (if GitHub blocked)
  corp-mirror/zsh-syntax-highlighting
  corp-mirror/zsh-autosuggestions
)

plugin-load
```

### Installation in Restricted Environment

**Option 1: Manual Installation**

```bash
# Download pulsar.zsh to approved location
cp /approved/shared/pulsar.zsh ~/.local/share/pulsar/pulsar.zsh

# Add to .zshrc manually
vim ~/.zshrc
```

**Option 2: Internal Mirror**

```bash
# Use internal installer
sh -c "$(curl -fsSL https://internal-mirror.corp.com/pulsar/install.sh)"
```

### Compliance Features

1. **No sudo required**: All user-space installation
2. **Audit trail**: All clones logged (can hook for audit)
3. **Version control**: Pin all plugins to approved versions
4. **No auto-update**: Explicit update control
5. **Transparent**: Pure shell script (easy to audit)

---

## Integration Patterns Summary

### Pattern 1: Declarative (Recommended)

```zsh
PULSAR_PLUGINS=(user/repo1 user/repo2)
plugin-load
```

**Pros**: Simple, automatic, works for 90% of use cases

### Pattern 2: Manual

```zsh
plugin-clone user/repo
plugin-load-manual user/repo
```

**Pros**: Fine-grained control, conditional loading

### Pattern 3: Hybrid

```zsh
# Declarative for most
PULSAR_PLUGINS=(user/repo1)
plugin-load

# Manual for special cases
if [[ condition ]]; then
  plugin-clone user/repo2
  plugin-load-manual user/repo2
fi
```

**Pros**: Balance of convenience and control

---

## Troubleshooting Quick Reference

### Plugin not loading

```bash
# Check if cloned
ls $PULSAR_HOME

# Check for init file
pulsar-check-conflicts

# Enable debug mode
PULSAR_DEBUG=1 exec zsh
```

### Slow startup

```bash
# Measure
time zsh -i -c exit

# Profile
zmodload zsh/zprof
# ... in .zshrc
zprof
```

### Conflicts between plugins

```bash
# Diagnostic
pulsar-check-conflicts

# Reorder plugins (last wins)
PULSAR_PLUGINS=(plugin-a plugin-b)  # plugin-b takes precedence
```

### Updates not working

```bash
# Manual update
plugin-update

# Check update channel
echo $PULSAR_UPDATE_CHANNEL

# Force update
PULSAR_UPDATE_CHANNEL=unstable pulsar-update
```

---

## Next Steps

- Read full documentation: `docs/README.md`
- Browse examples: `examples/`
- Report issues: GitHub issues
- Contribute: Pull requests welcome

---

## Quickstart Checklist

- [x] Fresh installation scenario documented
- [x] OMZ plugin usage documented
- [x] PATH and FPATH loading documented
- [x] Custom ZDOTDIR support documented
- [x] Version pinning documented
- [x] Local plugin development documented
- [x] OMZ migration guide provided
- [x] Manual control patterns documented
- [x] Performance optimization documented
- [x] Enterprise environment guidance provided
- [x] Integration patterns summarized
- [x] Troubleshooting reference provided
