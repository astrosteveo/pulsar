# Data Model: Minimal Zsh Plugin Manager (Pulsar)

**Feature**: Pulsar - Minimal Zsh Plugin Manager
**Date**: 2025-10-07
**Purpose**: Define data structures, entities, and relationships

## Overview

This document defines all data entities used by Pulsar, ensuring consistency and clarity across the implementation. All structures are implemented using Zsh native types (arrays, associative arrays, files).

---

## Entity 1: Plugin

**Description**: Represents a single plugin managed by Pulsar

**Storage**: Multiple representations depending on usage context

### Plugin Specification (User-Facing)

How users specify plugins in their .zshrc:

```zsh
# Simple GitHub shorthand
PULSAR_PLUGINS+=(romkatv/powerlevel10k)

# OMZ plugin with subdirectory
PULSAR_PLUGINS+=(ohmyzsh/ohmyzsh/plugins/git)

# With version pin
PULSAR_PLUGINS+=(user/repo@v1.2.3)

# Local path
PULSAR_PLUGINS+=(/path/to/local/plugin)

# Different loading modes
PULSAR_PATH+=(user/tool)        # Add bin/ to PATH
PULSAR_FPATH+=(user/completions) # Add to fpath only
```

### Plugin Metadata (Internal)

Stored in associative array during runtime:

```zsh
typeset -gA _PULSAR_PLUGIN_META

# Key format: plugin-identifier
# Value format: field1=value1|field2=value2|...

_PULSAR_PLUGIN_META[romkatv/powerlevel10k]="
  type=github
  repo=romkatv/powerlevel10k
  subdir=
  version=master
  local_path=/home/user/.cache/pulsar/romkatv--powerlevel10k
  init_file=/home/user/.cache/pulsar/romkatv--powerlevel10k/powerlevel10k.zsh-theme
  status=loaded
  kind=source
"
```

### Plugin Attributes

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `identifier` | string | Unique plugin identifier | `romkatv/powerlevel10k` |
| `type` | enum | Plugin source type | `github`, `local`, `url` |
| `repo` | string | Repository spec (owner/repo) | `romkatv/powerlevel10k` |
| `subdir` | string | Subdirectory path (for OMZ) | `plugins/git` |
| `version` | string | Git ref (branch/tag/commit) | `v1.2.3`, `main`, `abc123` |
| `local_path` | path | Absolute path to cached plugin | `/home/user/.cache/pulsar/romkatv--powerlevel10k` |
| `init_file` | path | Discovered init file path | `/home/user/.cache/pulsar/.../init.zsh` |
| `status` | enum | Current plugin state | `cloned`, `loaded`, `failed`, `missing` |
| `kind` | enum | Loading mode | `source`, `path`, `fpath` |

### Plugin States

```
     ┌─────────┐
     │ missing │ (not cloned yet)
     └────┬────┘
          │
     plugin-clone
          │
     ┌────▼────┐
     │ cloned  │ (exists in cache, not loaded)
     └────┬────┘
          │
     plugin-load
          │
     ┌────▼────┐
     │ loaded  │ (sourced into shell)
     └────┬────┘
          │
     error occurs
          │
     ┌────▼────┐
     │ failed  │ (error during load)
     └─────────┘
```

---

## Entity 2: Plugin Cache

**Description**: Filesystem-based storage for cloned plugin repositories

**Storage**: Directory structure under `$PULSAR_HOME`

### Directory Structure

```text
$PULSAR_HOME/
├── .pulsar-version              # Pulsar version that created cache
├── .pulsar-state                # Last update check, channel state
├── user1--repo1/                # Plugin directory (owner--repo)
│   ├── .git/                    # Git metadata
│   ├── init.zsh                 # Auto-discovered init file
│   ├── init.zwc                 # Compiled bytecode (optional)
│   └── [plugin files...]
├── user2--repo2/
│   └── ...
└── ohmyzsh--ohmyzsh/            # OMZ monorepo clone
    ├── plugins/
    │   ├── git/                 # Subdirectory plugin
    │   │   └── git.plugin.zsh
    │   ├── docker/
    │   │   └── docker.plugin.zsh
    │   └── ...
    └── themes/
        └── ...
```

### Cache Naming Convention

- GitHub plugins: `{owner}--{repo}` (double dash separator)
- Avoids `/` in directory names (filesystem safe)
- Preserves uniqueness (owner and repo)

### Cache Metadata Files

#### `.pulsar-version`

```text
1.0.0
```

Purpose: Track which Pulsar version created the cache (for migration)

#### `.pulsar-state`

```ini
last_update_check=1696723200
update_channel=stable
last_self_update=1696723200
```

Purpose: Track update state

---

## Entity 3: Plugin Arrays

**Description**: User-configurable arrays that define which plugins to load and how

**Storage**: Zsh arrays in user's .zshrc

### PULSAR_PLUGINS

Plugins to source (traditional loading):

```zsh
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  ohmyzsh/ohmyzsh/plugins/git
)
```

**Semantics**:

- Plugin is cloned (if missing)
- Init file is discovered
- Init file is sourced into shell
- Commands/functions become available

### PULSAR_PATH

Tools to add to `$PATH`:

```zsh
PULSAR_PATH=(
  junegunn/fzf
  sharkdp/fd
)
```

**Semantics**:

- Plugin is cloned (if missing)
- `bin/` directory (or equivalent) is added to `$PATH`
- No sourcing occurs
- Executables become available

### PULSAR_FPATH

Completions/prompts to add to `$fpath`:

```zsh
PULSAR_FPATH=(
  zsh-users/zsh-completions
)
```

**Semantics**:

- Plugin is cloned (if missing)
- Plugin directory added to `$fpath`
- No sourcing occurs
- Completions/prompts become available for autoload

### Array Operations

```zsh
# Append (most common)
PULSAR_PLUGINS+=(new/plugin)

# Prepend (for priority)
PULSAR_PLUGINS=(high-priority/plugin $PULSAR_PLUGINS)

# Remove (during troubleshooting)
PULSAR_PLUGINS=(${PULSAR_PLUGINS:#plugin-to-remove})

# Conditional loading
[[ $OSTYPE == darwin* ]] && PULSAR_PLUGINS+=(mac-only/plugin)
```

---

## Entity 4: Init File

**Description**: Entry point script for a plugin that provides commands/functions

**Storage**: File within plugin directory

### Common Names

Ordered by discovery precedence:

1. `{plugin-name}.plugin.zsh` - OMZ standard, most specific
2. `{plugin-name}.zsh` - Alternative naming
3. `init.zsh` - Generic convention
4. `*.plugin.zsh` - Fallback for OMZ subdirs
5. `*.zsh` - Last resort

### Example Init File

```zsh
# In plugin directory: romkatv/powerlevel10k/powerlevel10k.zsh-theme

# Check for dependencies
[[ -n ${ZSH_VERSION} ]] || return 1

# Define functions
function prompt_powerlevel10k_setup() {
  # ...
}

# Register prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd prompt_powerlevel10k_setup
```

### Init File Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `path` | string | Absolute file path |
| `size` | integer | File size in bytes |
| `mtime` | timestamp | Last modification time |
| `compiled` | boolean | Whether .zwc exists and is newer |

---

## Entity 5: Bootstrap File

**Description**: User's configuration file that loads Pulsar and defines plugins

**Storage**: File in user's Zsh configuration directory

### Typical Location

```text
~/.zshrc                          # Standard location
$ZDOTDIR/.zshrc                   # Custom ZDOTDIR
$ZSH/lib/pulsar-bootstrap.zsh     # Separate bootstrap file
```

### Bootstrap Structure

```zsh
# ===== Pulsar Configuration =====

# Load Pulsar
source /path/to/pulsar.zsh

# Configure plugins
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# Apply configuration
plugin-load
```

### Bootstrap Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `path` | string | Absolute path to bootstrap file |
| `backup_path` | string | Backup file path (with timestamp) |
| `has_pulsar_block` | boolean | Whether Pulsar block exists |
| `pulsar_version` | string | Pulsar version in use |

---

## Entity 6: Update Channel

**Description**: Configuration for automatic update behavior

**Storage**: Variable in user's .zshrc, state in cache

### Channel Types

| Channel | Behavior | Use Case |
|---------|----------|----------|
| `stable` | Check for updates on startup, prompt | Default, most users |
| `unstable` | Auto-update on startup, no prompt | Bleeding edge users |
| `off` | Never check for updates | Corporate/locked environments |

### Channel Configuration

```zsh
# In .zshrc
PULSAR_UPDATE_CHANNEL=stable  # Default
# or
PULSAR_UPDATE_CHANNEL=unstable
# or
PULSAR_UPDATE_CHANNEL=off
```

### Update State

Stored in `$PULSAR_HOME/.pulsar-state`:

```ini
last_update_check=1696723200    # Unix timestamp
update_channel=stable
last_self_update=1696723200
next_update_check=1696809600    # Calculated based on channel
```

### Update Flow

```
Shell Startup
     │
     ▼
Check Channel
     │
     ├──► off ───► Skip
     │
     ├──► stable ───► Check timestamp ───► >24h? ───► Prompt
     │                                          │
     │                                          └──► <24h ───► Skip
     │
     └──► unstable ───► Check timestamp ───► >6h? ───► Auto-update
                                                 │
                                                 └──► <6h ───► Skip
```

---

## Entity 7: Command Source Tracking

**Description**: Maps commands to the plugin that provides them (for conflict detection)

**Storage**: Associative array in runtime

### Structure

```zsh
typeset -gA _PULSAR_COMMAND_SOURCES

# Key: command name
# Value: plugin identifier

_PULSAR_COMMAND_SOURCES[kubectl]="plugin-a"
_PULSAR_COMMAND_SOURCES[docker]="plugin-b"
```

### Conflict Detection

```zsh
# Before loading plugin-c
_PULSAR_COMMAND_SOURCES[kubectl]="plugin-a"

# Plugin-c also provides kubectl
# Result: Warning
[pulsar] Plugin 'plugin-c' failed: command 'kubectl' conflicts with plugin-a
```

### Diagnostic Output

```text
$ pulsar-check-conflicts

Plugin Command Conflicts:
=========================
Command 'kubectl' provided by:
  - plugin-a
  - plugin-c (loaded last, takes precedence)

Command 'docker' provided by:
  - plugin-b (no conflicts)
```

---

## Relationships

### Plugin → Plugin Cache

- **Cardinality**: 1:1
- **Relationship**: Each plugin has exactly one cache directory
- **Example**: `romkatv/powerlevel10k` → `$PULSAR_HOME/romkatv--powerlevel10k/`

### Plugin Cache → Init File

- **Cardinality**: 1:0..1
- **Relationship**: Each cached plugin may have one init file (discovered)
- **Example**: `$PULSAR_HOME/romkatv--powerlevel10k/` → `powerlevel10k.zsh-theme`

### Plugin Arrays → Plugin

- **Cardinality**: Many:Many
- **Relationship**: Each array contains multiple plugins, plugins may appear in multiple arrays
- **Example**: `ohmyzsh/ohmyzsh/plugins/git` appears in `PULSAR_PLUGINS`, but `junegunn/fzf` appears in `PULSAR_PATH`

### Bootstrap File → Plugin Arrays

- **Cardinality**: 1:Many
- **Relationship**: Bootstrap file defines multiple plugin arrays
- **Example**: `.zshrc` defines `PULSAR_PLUGINS`, `PULSAR_PATH`, `PULSAR_FPATH`

### Update Channel → Plugin Cache

- **Cardinality**: 1:1
- **Relationship**: Each cache has one update channel configuration
- **Example**: Cache has `update_channel=stable` in `.pulsar-state`

### Command Source Tracking → Plugin

- **Cardinality**: Many:Many
- **Relationship**: Each command maps to one plugin, each plugin may provide multiple commands
- **Example**: `kubectl` → `plugin-a`, `docker` → `plugin-b`

---

## Data Flow Diagram

```
┌──────────────┐
│   User's     │
│   .zshrc     │◄────── Install adds Pulsar block
└──────┬───────┘
       │
       │ defines
       │
       ▼
┌──────────────┐
│    Plugin    │
│    Arrays    │
│ (PULSAR_*)   │
└──────┬───────┘
       │
       │ processed by
       │
       ▼
┌──────────────┐
│  plugin-load │
│   function   │
└──────┬───────┘
       │
       │ checks existence
       │
       ▼
┌──────────────┐     missing     ┌──────────────┐
│    Plugin    │────────────────►│ plugin-clone │
│    Cache     │                 │   function   │
└──────┬───────┘                 └──────────────┘
       │
       │ exists
       │
       ▼
┌──────────────┐
│  Init File   │
│  Discovery   │
└──────┬───────┘
       │
       │ source / PATH / fpath
       │
       ▼
┌──────────────┐
│   Loaded     │
│   Plugin     │
└──────────────┘
       │
       │ tracks
       │
       ▼
┌──────────────┐
│   Command    │
│   Sources    │
└──────────────┘
```

---

## Implementation Notes

### Memory Efficiency

- Use associative arrays sparingly (only for metadata tracking)
- Prefer simple arrays for plugin lists
- Avoid loading entire cache into memory
- Lazy-load metadata only when needed

### File System Operations

- Always use absolute paths
- Handle ZDOTDIR and XDG_CACHE_HOME correctly
- Create parent directories as needed
- Validate paths before operations

### Concurrency

- Plugin cache is shared across all shells
- Use file locking for concurrent operations (updates, clones)
- Read operations don't need locking

### Validation

- Validate plugin specs before cloning
- Validate paths before sourcing
- Validate arrays are not empty before iteration

---

## Data Model Checklist

- [x] Plugin entity defined with all attributes
- [x] Plugin Cache structure defined
- [x] Plugin Arrays semantics documented
- [x] Init File discovery patterns documented
- [x] Bootstrap File structure defined
- [x] Update Channel types and flow defined
- [x] Command Source Tracking for conflicts defined
- [x] Relationships between entities documented
- [x] Data flow diagram created
- [x] Implementation notes provided

---

## Next Steps

1. Implement data structures in pulsar.zsh
2. Create cache initialization functions
3. Implement plugin metadata tracking
4. Add command source tracking during load
5. Create diagnostic functions for cache inspection
6. Write tests for data structure operations
