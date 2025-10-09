# Data Model

**Feature**: 002-pulsar-minimal-zsh
**Date**: 2025-10-08
**Status**: Implemented

## Overview

Pulsar's data model is minimal and file-system based, reflecting its nature as a shell plugin manager. There are no databases or complex data structures—instead, the system uses the file system, Zsh arrays, and simple state files.

## Core Entities

### 1. Plugin

**Description**: A Git repository containing Zsh code to be integrated into the shell environment.

**Attributes**:

- **spec** (string): The plugin specification as declared by user
  - Format: `[prefix:]user/repo[@ref][/subpath]`
  - Examples: `zsh-users/zsh-autosuggestions`, `OMZP::git`, `path:user/repo`, `user/repo@v1.0.0`
- **remote_url** (string): The Git repository URL
  - Derived from spec
  - Format: `https://github.com/user/repo`
- **local_path** (string): Absolute path to cloned repository
  - Format: `$XDG_CACHE_HOME/pulsar/repos/user/repo`
  - Exists after clone operation
- **entry_point** (string): Path to file that should be sourced
  - Discovered via 5-step precedence
  - Examples: `plugin.zsh`, `init.zsh`, `git.plugin.zsh`
- **loading_mode** (enum): How the plugin integrates with shell
  - Values: `source`, `path`, `fpath`
  - Default: `source`
- **version_ref** (string, optional): Git reference to pin version
  - Format: tag, branch, or commit SHA
  - Examples: `v1.0.0`, `develop`, `abc123`
- **subpath** (string, optional): Subdirectory within repository
  - Used for monorepo plugins
  - Example: `plugins/git` for OMZ plugins

**State Transitions**:

1. **Declared** → User adds plugin to `PULSAR_PLUGINS` array
2. **Cloned** → `plugin-clone` fetches repository
3. **Loaded** → Entry point sourced into shell
4. **Updated** → `plugin-update` pulls latest changes (respecting pinned refs)

**Relationships**:

- Plugin **contains** Entry Point (one-to-one)
- Plugin **stored in** Cache Directory (many-to-one)
- Plugin **uses** Loading Mode (many-to-one)

**Validation Rules**:

- Spec must be non-empty string
- Remote URL must be valid Git repository
- Local path must be writable
- Entry point must exist and be readable after discovery
- Version ref (if specified) must exist in repository

**Examples**:

```zsh
# Basic plugin
spec="zsh-users/zsh-autosuggestions"
remote_url="https://github.com/zsh-users/zsh-autosuggestions"
local_path="/home/user/.cache/pulsar/repos/zsh-users/zsh-autosuggestions"
entry_point="zsh-autosuggestions.zsh"
loading_mode="source"

# OMZ plugin with shorthand
spec="OMZP::git"
remote_url="https://github.com/ohmyzsh/ohmyzsh"
local_path="/home/user/.cache/pulsar/repos/ohmyzsh/ohmyzsh"
entry_point="plugins/git/git.plugin.zsh"
loading_mode="source"

# Pinned version
spec="zsh-users/zsh-syntax-highlighting@v0.7.1"
version_ref="v0.7.1"

# PATH mode
spec="path:junegunn/fzf"
loading_mode="path"
```

### 2. Entry Point

**Description**: The specific file within a plugin repository that initializes the plugin.

**Attributes**:

- **file_path** (string): Absolute path to the entry point file
- **discovery_method** (enum): How the entry point was found
  - Values: `explicit_plugin_zsh`, `explicit_init_zsh`, `pattern_plugin_zsh`, `first_zsh`, `manual_override`
- **file_type** (enum): Type of entry point
  - Values: `plugin`, `lib`, `theme`, `script`
- **requires_compinit** (boolean): Whether entry point uses completions
  - Derived from presence of `compdef` commands
  - Used to trigger automatic `compinit` call

**Discovery Precedence**:

1. `plugin.zsh` (explicit plugin marker)
2. `init.zsh` (common convention)
3. `*.plugin.zsh` (OMZ pattern)
4. `*.zsh` (first alphabetically)
5. Manual override via function arguments

**Validation Rules**:

- File must exist at file_path
- File must be readable
- File must be regular file (not directory or symlink to directory)

**Examples**:

```zsh
# Standard plugin
file_path="/home/user/.cache/pulsar/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh"
discovery_method="first_zsh"
file_type="plugin"
requires_compinit=false

# OMZ plugin
file_path="/home/user/.cache/pulsar/repos/ohmyzsh/ohmyzsh/plugins/git/git.plugin.zsh"
discovery_method="pattern_plugin_zsh"
file_type="plugin"
requires_compinit=true
```

### 3. Cache Directory

**Description**: XDG-compliant storage location for cloned plugins and state files.

**Attributes**:

- **root_path** (string): Base cache directory
  - Default: `$XDG_CACHE_HOME/pulsar` or `~/.cache/pulsar`
  - Configurable via `PULSAR_HOME`
- **repos_path** (string): Directory containing cloned repositories
  - Format: `{root_path}/repos`
- **state_path** (string): Directory for state files
  - Format: `{root_path}/`
  - Contains update check timestamps, etc.

**Structure**:

```text
$XDG_CACHE_HOME/pulsar/
├── repos/                    # Cloned plugins
│   ├── user1/
│   │   ├── repo1/           # Plugin: user1/repo1
│   │   └── repo2/           # Plugin: user1/repo2
│   └── ohmyzsh/
│       └── ohmyzsh/         # OMZ repository
└── update_state             # Self-update state file
```

**Validation Rules**:

- Root path must be writable
- Directory structure auto-created on first use
- Old cache can be safely deleted (re-clones on next load)

**Lifecycle**:

- **Created**: First time Pulsar is sourced
- **Populated**: As plugins are cloned
- **Cleaned**: Manual user action (`rm -rf`)
- **Updated**: As plugins are updated via `plugin-update`

### 4. Update Channel

**Description**: Configuration determining source for Pulsar self-updates.

**Attributes**:

- **name** (enum): Channel identifier
  - Values: `stable`, `edge`, `off`
  - Aliases: `unstable` → `edge`
- **source** (enum): Where updates come from
  - `stable` → GitHub releases (tags)
  - `edge` → GitHub main branch
  - `off` → No updates
- **check_interval** (integer): Seconds between update checks
  - Default: 86400 (24 hours)
  - Configurable via `PULSAR_UPDATE_CHECK_INTERVAL`
- **notify_enabled** (boolean): Whether to show update notifications
  - Default: true
  - Configurable via `PULSAR_UPDATE_NOTIFY`

**State Storage**:

```zsh
# File: $XDG_CACHE_HOME/pulsar/update_state
LAST_CHECK_TIME=1728403200
AVAILABLE_VERSION=v0.7.0
CURRENT_VERSION=v0.6.0
```

**Validation Rules**:

- Name must be one of supported values
- Check interval must be positive integer
- State file must be readable/writable

**Examples**:

```zsh
# Stable channel (default)
PULSAR_UPDATE_CHANNEL=stable
source="github_releases"

# Edge channel
PULSAR_UPDATE_CHANNEL=edge
source="github_main_branch"

# Updates disabled
PULSAR_UPDATE_CHANNEL=off
```

### 5. Loading Mode

**Description**: Strategy for integrating a plugin into the shell environment.

**Attributes**:

- **mode_type** (enum): The loading strategy
  - Values: `source`, `path`, `fpath`
- **action** (string): What happens when plugin is loaded
  - `source`: Execute plugin entry point with `source` command
  - `path`: Add `{plugin}/bin` to `$PATH`
  - `fpath`: Add `{plugin}` to `$fpath` for completions

**Mode Details**:

#### Source Mode (Default)

- **When**: Plugin provides shell functions, aliases, or environment setup
- **Action**: `source {entry_point}`
- **Use Cases**: 95% of plugins
- **Example**: `zsh-users/zsh-autosuggestions`

#### PATH Mode

- **When**: Plugin provides binary executables
- **Action**: `path=({plugin}/bin $path)` (prepend to PATH)
- **Use Cases**: Tools like fzf, ripgrep
- **Example**: `path:junegunn/fzf`

#### fpath Mode

- **When**: Plugin provides only completion functions
- **Action**: `fpath=({plugin} $fpath)` (prepend to fpath)
- **Use Cases**: Completion-only plugins
- **Example**: `fpath:user/completions`

**Specification Syntax**:

```zsh
# Source mode (implicit default)
PULSAR_PLUGINS=(
  user/repo                # source mode
)

# Explicit mode via prefix
PULSAR_PLUGINS=(
  path:user/repo          # PATH mode
  fpath:user/repo         # fpath mode
)
```

## Data Flow

### Plugin Loading Flow

```text
1. User declares plugin in PULSAR_PLUGINS array
2. Pulsar expands shorthand (OMZP:: → ohmyzsh/ohmyzsh/plugins/...)
3. Parse spec for mode prefix and version ref
4. Check if plugin exists in cache
5. If not cached: Clone repository (with parallel jobs)
6. If version ref specified: Checkout ref
7. Discover entry point using 5-step precedence
8. Check if entry point requires compinit (has compdef)
9. Apply loading mode:
   - source: Execute entry point
   - path: Add bin/ to PATH
   - fpath: Add to fpath
10. If compinit needed and not done: Run compinit
```

### Plugin Update Flow

```text
1. User runs plugin-update [plugin...]
2. If no plugins specified: Update all in PULSAR_PLUGINS
3. For each plugin (parallel):
   - Change to plugin's local_path
   - If pinned to tag: Skip (tags don't update)
   - If pinned to branch/commit: git fetch && git checkout ref
   - If unpinned: git pull
   - Report success/failure
4. Aggregate results and display summary
```

### Self-Update Flow

```text
1. User runs pulsar-self-update or shell startup triggers check
2. Check channel configuration (stable/edge/off)
3. If off: Exit early
4. Check last update check timestamp
5. If interval not elapsed: Exit early (unless forced)
6. Fetch latest version info based on channel:
   - stable: GitHub API /repos/{owner}/{repo}/releases/latest
   - edge: git ls-remote {repo} main
7. Compare available version with PULSAR_VERSION
8. If newer version available:
   - Show notification (if notify enabled)
   - If interactive and prompt enabled: Ask to update
   - If confirmed: Download new pulsar.zsh, backup old, install new
9. Update state file with check timestamp and version info
```

## State Management

### In-Memory State

**Zsh Arrays**:

- `PULSAR_PLUGINS`: User-declared plugin list
- `_pulsar_loaded_plugins`: Tracking loaded plugins (prevents duplicates)

**Zsh Variables**:

- `PULSAR_VERSION`: Current version string
- `PULSAR_UPDATE_CHANNEL`: Update channel configuration
- `PULSAR_HOME`: Cache directory location

### Persistent State

**Files**:

- `$PULSAR_HOME/repos/*/*`: Cloned git repositories
- `$PULSAR_HOME/update_state`: Update check state

**State File Format**:

```bash
# Simple KEY=VALUE format, sourced as shell script
LAST_CHECK_TIME=1728403200
AVAILABLE_VERSION=v0.7.0
CURRENT_VERSION=v0.6.0
```

## Error States

### Plugin Load Errors

- **Repository not found**: Git clone fails with 404
- **Network unavailable**: Git clone times out
- **Entry point not found**: No matching file in plugin
- **Entry point not readable**: Permission denied
- **Invalid version ref**: Git checkout fails

**Handling**: Warn user, skip plugin, continue loading others

### Update Errors

- **Detached HEAD state**: Git pull fails
- **Local modifications**: Git pull conflicts
- **Network timeout**: Git fetch fails

**Handling**: Report error for specific plugin, continue updating others

### Self-Update Errors

- **GitHub API rate limit**: Fall back to cached info
- **Download failure**: Keep current version
- **Backup failure**: Abort update

**Handling**: Graceful degradation, clear error messages

## Performance Considerations

### Memory Usage

- Minimal: Only arrays and strings in memory
- No large data structures
- Plugin code loaded into shell (normal Zsh behavior)

### Disk Usage

- Proportional to number and size of plugins
- Typical plugin: 100KB - 5MB
- OMZ repository: ~40MB
- Cache can be safely deleted (auto-recreates)

### Network Usage

- Initial clone: Full repository download
- Updates: Incremental (git fetch/pull)
- Self-update: Single file download (~50KB)
- API calls: Minimal (update checks only)

## Concurrency Model

### Parallel Cloning

- **Mechanism**: Zsh background jobs (`&` operator)
- **Coordination**: `wait` command with PID tracking
- **Bound**: Number of CPU cores (`nproc` or 4)
- **Locking**: Git handles repository-level locking

### Race Conditions

- **Multiple shells**: Git clone is safe (atomic operations)
- **Concurrent updates**: Git handles locking
- **State file**: Last-write-wins (acceptable for update checks)

## Validation & Constraints

### Input Validation

- Plugin specs must be non-empty strings
- Version refs validated by git (checkout fails gracefully)
- File paths normalized and sanitized
- URLs constructed from trusted patterns

### System Constraints

- Git must be available on PATH
- Cache directory must be writable
- Network required for clone/update (degrades gracefully when offline)
- Zsh 5.8+ required for modern parameter expansion

### Resource Limits

- Parallel jobs bounded by CPU cores
- No hard limit on plugin count (tested with 100+)
- File descriptor limits respected (git handles this)

## Extension Points

### Future Data Model Additions

1. **Plugin Metadata**:
   - Description, author, homepage
   - Could be stored in `plugin.zsh` header comments
   - Enables plugin registry/search

2. **Dependency Graph**:
   - Plugins declaring dependencies on other plugins
   - Load order resolution
   - Enables complex plugin ecosystems

3. **Conflict Detection**:
   - Track which functions/aliases each plugin defines
   - Warn on conflicts
   - Enables better plugin composition

4. **Usage Analytics** (opt-in):
   - Track which plugins are most popular
   - Load time profiling per plugin
   - Enables ecosystem insights
