# API Contract: plugin-load

**Feature**: 002-pulsar-minimal-zsh
**Function**: `plugin-load`
**Purpose**: Load one or more plugins into the current shell environment

## Signature

```zsh
plugin-load <plugin-spec> [plugin-spec...]
```

## Parameters

### plugin-spec (required, variadic)

- **Type**: String or Array
- **Format**: `[prefix:]user/repo[@ref][/subpath]`
- **Description**: Plugin specification(s) to load
- **Accepts**: Individual arguments or array variable
- **Examples**:
  - `plugin-load zsh-users/zsh-autosuggestions`
  - `plugin-load $PULSAR_PLUGINS` (array expansion)
  - `plugin-load OMZP::git OMZP::docker`
- **Validation**:
  - Must be non-empty
  - Shorthand expanded automatically
  - Mode prefixes extracted and processed

## Return Values

- **Exit Code 0**: All plugins loaded successfully (or gracefully handled failures)
- **Exit Code 1**: Critical failure (rare, most errors are warnings)

## Side Effects

### Shell Environment

- **Sources plugin files**: Executes entry point with `source` command (source mode)
- **Modifies PATH**: Prepends plugin/bin to PATH (path mode)
- **Modifies fpath**: Prepends plugin directory to fpath (fpath mode)
- **Defines functions**: Plugin functions become available in shell
- **Sets variables**: Plugin variables exported to environment
- **Defines aliases**: Plugin aliases become active

### File System

- Reads from `$PULSAR_HOME/repos/*/*` (cloned plugins)
- May trigger `plugin-clone` if plugin not cached
- Optional: Creates `.zwc` bytecode files (if `PULSAR_AUTOCOMPILE=1`)

### Standard Output

- Progress messages during load (if TTY and progress enabled)
- Entry point discovery messages
- Success confirmation per plugin

### Standard Error

- Warning messages for missing plugins
- Error messages for load failures
- Continues loading other plugins after errors

### Completion System

- Calls `compinit` automatically if:
  - Plugin uses `compdef` (detected via grep)
  - `compinit` not yet called in session
  - Ensures completions work without manual user intervention

## Behavior

### Normal Flow

1. Parse plugin spec (expand shorthand, extract mode, ref, subpath)
2. Check if plugin already loaded (prevent duplicate loading)
3. Check if plugin cloned in cache
4. If not cloned: Call `plugin-clone` automatically
5. Determine entry point using 5-step precedence
6. Detect if entry point requires compinit (grep for compdef)
7. Apply loading mode:
   - **source**: `source {entry_point}`
   - **path**: `path=({plugin}/bin $path)`
   - **fpath**: `fpath=({plugin} $fpath)`
8. If compinit needed and not done: Run `compinit`
9. Mark plugin as loaded
10. Report success

### Entry Point Discovery Precedence

1. `plugin.zsh` (explicit plugin marker)
2. `init.zsh` (common convention)
3. `*.plugin.zsh` (Oh-My-Zsh pattern, first alphabetically)
4. `*.zsh` (any Zsh file, first alphabetically)
5. Error if none found

### Loading Modes

#### Source Mode (Default)

- Most common mode (95% of plugins)
- Executes plugin initialization code
- Defines functions, aliases, sets variables

```zsh
plugin-load zsh-users/zsh-autosuggestions
# Sources: $PULSAR_HOME/repos/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
```

#### PATH Mode

- For plugins providing binary executables
- Adds `{plugin}/bin` to PATH
- Does not source any files

```zsh
plugin-load path:junegunn/fzf
# Modifies: path=($PULSAR_HOME/repos/junegunn/fzf/bin $path)
```

#### fpath Mode

- For completion-only plugins
- Adds plugin directory to fpath
- Does not source any files (completions loaded by compinit)

```zsh
plugin-load fpath:user/completions
# Modifies: fpath=($PULSAR_HOME/repos/user/completions $fpath)
```

### Parallel Cloning

- If multiple plugins need cloning, clones them in parallel
- Waits for all clones to complete before loading
- Bounded parallelism (CPU core count)

### Deduplication

- Tracks loaded plugins in `_pulsar_loaded_plugins` array
- Skips plugins already loaded in current session
- Prevents duplicate function definitions and sourcing

## Examples

### Load Single Plugin

```zsh
$ plugin-load zsh-users/zsh-autosuggestions
📦 Cloning zsh-users/zsh-autosuggestions...
🔍 Found entry point: zsh-autosuggestions.zsh
✅ Loaded zsh-users/zsh-autosuggestions
```

### Load Array of Plugins

```zsh
typeset -ga PULSAR_PLUGINS=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  OMZP::git
)
plugin-load $PULSAR_PLUGINS
# Loads all three plugins
```

### Load with Shorthand

```zsh
$ plugin-load OMZP::git OMZL::completion OMZT::robbyrussell
🔍 Found entry point: plugins/git/git.plugin.zsh
🔍 Found entry point: lib/completion.zsh
🔍 Found entry point: themes/robbyrussell.zsh-theme
✅ Loaded OMZP::git
✅ Loaded OMZL::completion
✅ Loaded OMZT::robbyrussell
```

### Load with Version Pinning

```zsh
$ plugin-load zsh-users/zsh-autosuggestions@v0.7.0
🔒 Using pinned version: v0.7.0
✅ Loaded zsh-users/zsh-autosuggestions@v0.7.0
```

### Load PATH Plugin

```zsh
$ plugin-load path:junegunn/fzf
🔍 Adding to PATH: .../fzf/bin
✅ Loaded path:junegunn/fzf
```

### Already Loaded

```zsh
$ plugin-load zsh-users/zsh-autosuggestions
⏭️  zsh-users/zsh-autosuggestions already loaded
```

### Entry Point Not Found

```zsh
$ plugin-load user/empty-repo
❌ No entry point found in user/empty-repo
   Checked: plugin.zsh, init.zsh, *.plugin.zsh, *.zsh
```

## Dependencies

### External Commands

- `git` (optional, for auto-cloning)
- `grep` (for compdef detection)

### Zsh Builtins

- `source` command
- Array manipulation
- Parameter expansion
- `compinit` (for completion system)

### Internal Functions

- `plugin-clone`: Auto-clone missing plugins
- `pulsar__expand_shorthand`: Shorthand expansion
- `pulsar__find_entry_point`: Entry point discovery
- `pulsar__cecho`: Colored output
- `warn`: Warning messages

## Performance Characteristics

- **Cache hit (plugin cloned)**: <10ms per plugin
- **Cache miss (needs clone)**: ~3 seconds per plugin (network-dependent)
- **Parallel cloning**: ~3 seconds for 10 plugins (with 4 cores)
- **Overhead per plugin**: <1ms (array checks, path manipulation)
- **Total manager overhead**: <50ms for typical setup

## Configuration

### Environment Variables Used

- `PULSAR_HOME`: Cache directory location
- `PULSAR_PLUGINS`: Default plugin list (if loaded without args)
- `PULSAR_AUTOCOMPILE`: Enable bytecode compilation
- `PULSAR_PROGRESS`: Control progress output
- `PULSAR_COLOR`: Control colored output
- `PULSAR_FORCE_RECLONE`: Force re-cloning

### Respects

- TTY detection for output
- `NO_COLOR` environment variable
- XDG Base Directory specification

## Error Handling

### Recoverable Errors (Warnings)

- Plugin not cloned: Attempt auto-clone
- Entry point not found: Warn and skip
- Permission denied: Warn and skip
- Invalid ref: Warn after clone attempt

### Continue on Error

- Load failures for one plugin don't stop loading others
- All plugins in list processed even if some fail
- Error summary provided at end

## Automatic Behaviors

### Auto-Clone

- Plugins not in cache are automatically cloned
- No explicit `plugin-clone` call needed
- Parallel cloning for efficiency

### Auto-compinit

- Detects `compdef` usage in plugin files
- Automatically calls `compinit` if needed
- Ensures completions work immediately
- One-time per session (not repeated)

### Auto-Discovery

- Entry points discovered automatically
- No manual specification needed for 95% of plugins
- Fallback to first .zsh file if no standard entry point

## Idempotency

- Safe to call multiple times with same plugin
- Deduplication prevents re-loading
- No side effects on repeated calls (beyond first load)

## Thread Safety

- Multiple shells can load plugins concurrently
- Cache directory shared safely
- Each shell maintains own loaded plugin list

## Testing

### Test Cases

1. Load plugin successfully (source mode)
2. Load plugin in PATH mode
3. Load plugin in fpath mode
4. Auto-clone missing plugin
5. Skip already-loaded plugin
6. Expand shorthand aliases
7. Discover entry point automatically
8. Handle missing entry point gracefully
9. Auto-initialize completions
10. Load array of plugins
11. Respect version pinning
12. Continue loading after error
13. Handle OMZ plugin structure
14. Handle Prezto module structure
15. Compile plugins if autocompile enabled

### Validation

- Verify functions defined after load
- Check PATH modified (path mode)
- Check fpath modified (fpath mode)
- Confirm entry point sourced
- Validate compinit called when needed
- Verify no duplicate loading
