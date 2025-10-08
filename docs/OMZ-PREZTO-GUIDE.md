# Oh-My-Zsh and Prezto Plugin Integration Guide

This guide explains how Pulsar handles Oh-My-Zsh (OMZ) and Prezto plugins, including the architectural decisions and usage patterns.

## Overview

Pulsar supports loading plugins from both Oh-My-Zsh and Prezto frameworks without requiring full installation of those frameworks. This is achieved by:

1. **Cloning only the base repository** (e.g., `ohmyzsh/ohmyzsh` or `sorin-ionescu/prezto`)
2. **Loading specific subdirectories** (plugins, lib files, themes, or modules)
3. **Automatic detection** of file vs. directory structures

## Oh-My-Zsh Plugin Structure

Oh-My-Zsh has three main types of loadable components:

### 1. Plugins (Directories)
- Location: `plugins/<name>/`
- Init file: `<name>.plugin.zsh`
- Example: `plugins/git/git.plugin.zsh`

**Usage:**
```zsh
PULSAR_PLUGINS=(
  ohmyzsh/ohmyzsh/plugins/git
  # or use shorthand:
  OMZP::git
)
```

### 2. Library Files (Direct Files)
- Location: `lib/<name>.zsh`
- These are standalone `.zsh` files, NOT directories
- Example: `lib/completion.zsh`

**Usage:**
```zsh
PULSAR_PLUGINS=(
  ohmyzsh/ohmyzsh/lib/completion
  # or use shorthand:
  OMZL::completion
)
```

### 3. Themes (Direct Files)
- Location: `themes/<name>.zsh-theme`
- These are standalone `.zsh-theme` files, NOT directories
- Example: `themes/robbyrussell.zsh-theme`

**Usage:**
```zsh
PULSAR_PLUGINS=(
  ohmyzsh/ohmyzsh/themes/robbyrussell
  # or use shorthand:
  OMZT::robbyrussell
)
```

## Prezto Module Structure

Prezto organizes plugins as "modules":

### Modules (Directories)
- Location: `modules/<name>/`
- Init file: `init.zsh`
- Example: `modules/git/init.zsh`

**Usage:**
```zsh
PULSAR_PLUGINS=(
  sorin-ionescu/prezto/modules/git
  # or use shorthand:
  PZT::git
)
```

## How It Works

### Clone Strategy

When you specify a plugin with a subdirectory (e.g., `ohmyzsh/ohmyzsh/plugins/git`):

1. **Pulsar extracts the base repository**: `ohmyzsh/ohmyzsh`
2. **Clones only the base repo once**: Efficient - multiple plugins from the same repo share one clone
3. **Loads from the subdirectory**: `plugins/git/`

This is the same approach used by zinit and other modern plugin managers.

### File Discovery

The `plugin-script` function intelligently detects whether a path points to:

**A Directory** (like plugins):
- Looks for `<name>.plugin.zsh` inside the directory
- Falls back to `*.plugin.zsh`, `init.zsh`, etc.

**A File** (like lib or themes):
- Looks for `<path>.zsh` or `<path>.zsh-theme`
- Example: `lib/completion` → `lib/completion.zsh`

### Discovery Algorithm

```zsh
# For spec: ohmyzsh/ohmyzsh/lib/completion
repo_path="ohmyzsh/ohmyzsh"
subdir_path="lib/completion"
full_path="$PULSAR_HOME/ohmyzsh/ohmyzsh/lib/completion"

if [[ -d "$full_path" ]]; then
  # It's a directory - look inside for init files
  search for: $full_path/<name>.plugin.zsh, init.zsh, etc.
else
  # Not a directory - try as direct file
  search for: $full_path.zsh, $full_path.zsh-theme, etc.
fi
```

## Shorthand Aliases

Pulsar provides convenient shorthand aliases:

| Shorthand | Expands To | Use Case |
|-----------|------------|----------|
| `OMZP::` | `ohmyzsh/ohmyzsh/plugins/` | OMZ plugins |
| `OMZL::` | `ohmyzsh/ohmyzsh/lib/` | OMZ library files |
| `OMZT::` | `ohmyzsh/ohmyzsh/themes/` | OMZ themes |
| `PZT::` | `sorin-ionescu/prezto/modules/` | Prezto modules |

## Examples

### Loading Multiple OMZ Plugins

```zsh
PULSAR_PLUGINS=(
  # OMZ plugins
  OMZP::git
  OMZP::docker
  OMZP::kubectl
  
  # OMZ lib files
  OMZL::completion
  OMZL::key-bindings
  
  # OMZ theme
  OMZT::robbyrussell
  
  # Standard plugins
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
```

### Loading Prezto Modules

```zsh
PULSAR_PLUGINS=(
  # Prezto modules
  PZT::git
  PZT::completion
  PZT::syntax-highlighting
  
  # Can mix with other plugins
  romkatv/powerlevel10k
)
```

### Mixed Configuration

```zsh
PULSAR_PLUGINS=(
  # Prezto
  PZT::environment
  PZT::editor
  
  # OMZ
  OMZP::git
  OMZL::completion
  
  # Standard GitHub plugins
  zsh-users/zsh-autosuggestions
  romkatv/powerlevel10k
)
```

## Error Handling

Pulsar provides detailed error messages for common issues:

### Repository Not Found
```
Pulsar: Failed to clone OMZP::git
Pulsar: Repository 'ohmyzsh/ohmyzsh' does not exist on https://github.com/
```

### Network Error
```
Pulsar: Failed to clone OMZP::git
Pulsar: Network error - check your internet connection
```

### Plugin Not Found After Clone
```
Pulsar: No plugin init found for 'OMZP::nonexistent'
Pulsar: Expected either:
  - Directory: /cache/ohmyzsh/ohmyzsh/plugins/nonexistent/ with init files inside
  - Direct file: /cache/ohmyzsh/ohmyzsh/plugins/nonexistent.zsh
```

## Idempotency

Pulsar automatically handles idempotency:

- **First run**: Clones the repository
- **Subsequent runs**: Skips cloning if repo already exists
- **Force re-clone**: Set `PULSAR_FORCE_RECLONE=1` to force re-cloning

```zsh
# Normal behavior - skip if exists
plugin-clone OMZP::git

# Force re-clone
PULSAR_FORCE_RECLONE=1 plugin-clone OMZP::git
```

## Cache Structure

```
$PULSAR_HOME/
├── ohmyzsh/
│   └── ohmyzsh/          # Full OMZ repo clone
│       ├── plugins/
│       │   ├── git/      # Plugin directory
│       │   └── docker/
│       ├── lib/
│       │   ├── completion.zsh     # Direct file
│       │   └── key-bindings.zsh
│       └── themes/
│           └── robbyrussell.zsh-theme
├── sorin-ionescu/
│   └── prezto/           # Full Prezto repo clone
│       └── modules/
│           ├── git/      # Module directory
│           └── completion/
└── zsh-users/
    ├── zsh-syntax-highlighting/
    └── zsh-autosuggestions/
```

## Troubleshooting

### Plugin Won't Load

1. **Verify the repository was cloned**:
   ```zsh
   ls $PULSAR_HOME/ohmyzsh/ohmyzsh
   ```

2. **Check if the plugin exists**:
   ```zsh
   ls $PULSAR_HOME/ohmyzsh/ohmyzsh/plugins/git
   # or for lib:
   ls $PULSAR_HOME/ohmyzsh/ohmyzsh/lib/completion.zsh
   ```

3. **Try force re-cloning**:
   ```zsh
   PULSAR_FORCE_RECLONE=1 plugin-clone OMZP::git
   ```

### Wrong File Type

If Pulsar is looking for the wrong file type:

- **For directories**: Make sure the plugin is actually a directory in the OMZ repo
- **For files**: Check that it's a standalone file, not a directory

### Completions Not Working

OMZ plugins require `compinit` to be called. Pulsar automatically initializes completions when loading OMZ plugins:

```zsh
# This happens automatically:
Pulsar: Initializing Zsh completions (required for Oh-My-Zsh plugins)...
```

## Performance Considerations

### Efficient Cloning

Since Pulsar clones the full base repository:
- Multiple plugins from the same repo share one clone
- Example: `OMZP::git`, `OMZP::docker`, `OMZL::completion` all use the same `ohmyzsh/ohmyzsh` clone

### Compilation

Pulsar can compile plugin files for faster loading:
```zsh
plugin-compile
# or automatically:
PULSAR_AUTOCOMPILE=1
```

## Migration from OMZ/Prezto

### From Oh-My-Zsh

**Before:**
```zsh
plugins=(git docker kubectl)
source $ZSH/oh-my-zsh.sh
```

**After:**
```zsh
PULSAR_PLUGINS=(
  OMZP::git
  OMZP::docker
  OMZP::kubectl
)
source /path/to/pulsar.zsh
```

### From Prezto

**Before:**
```zsh
zstyle ':prezto:load' pmodule 'git' 'completion'
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
```

**After:**
```zsh
PULSAR_PLUGINS=(
  PZT::git
  PZT::completion
)
source /path/to/pulsar.zsh
```

## Advanced Usage

### Version Pinning

```zsh
PULSAR_PLUGINS=(
  # Pin OMZ to specific version
  ohmyzsh/ohmyzsh/plugins/git@v1.0.0
  
  # Mix pinned and unpinned
  OMZP::docker
)
```

### Custom Git URL

```zsh
# Use a mirror or fork
PULSAR_GITURL="https://gitee.com/" plugin-clone OMZP::git
```

## Summary

Pulsar's OMZ and Prezto support provides:

✅ **No framework installation required**
✅ **Efficient caching** - one clone serves multiple plugins
✅ **Intelligent file detection** - handles directories and files correctly
✅ **Comprehensive error handling** - helpful messages for debugging
✅ **Idempotent operations** - safe to run multiple times
✅ **Backward compatible** - works with existing plugin specs
✅ **Easy migration** - simple transition from OMZ/Prezto

The implementation follows the same proven approach as zinit, ensuring reliability and performance.
