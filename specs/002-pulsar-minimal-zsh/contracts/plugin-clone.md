# API Contract: plugin-clone

**Feature**: 002-pulsar-minimal-zsh
**Function**: `plugin-clone`
**Purpose**: Clone a plugin repository from Git to local cache

## Signature

```zsh
plugin-clone <plugin-spec> [plugin-spec...]
```

## Parameters

### plugin-spec (required, variadic)

- **Type**: String
- **Format**: `[prefix:]user/repo[@ref][/subpath]`
- **Description**: Plugin specification to clone
- **Examples**:
  - `zsh-users/zsh-autosuggestions`
  - `OMZP::git`
  - `user/repo@v1.0.0`
  - `path:junegunn/fzf`
- **Validation**:
  - Must be non-empty
  - Must contain at least `user/repo` structure
  - Shorthand (OMZP::, OMZL::, etc.) expanded before processing

## Return Values

- **Exit Code 0**: All clones succeeded
- **Exit Code 1**: One or more clones failed (continues processing all)

## Side Effects

### File System

- Creates `$XDG_CACHE_HOME/pulsar/repos/{user}/{repo}/` directory
- Clones git repository into that directory
- If `@ref` specified, checks out that ref after clone

### Standard Output

- Progress messages (if `PULSAR_PROGRESS` enabled and TTY)
- Success messages: "Cloned user/repo"
- Example: `📦 Cloning zsh-users/zsh-autosuggestions...`

### Standard Error

- Error messages for failed clones
- Example: `❌ Failed to clone user/repo: repository not found`

### Environment

- No environment variables modified
- Uses existing `PULSAR_HOME`, `PULSAR_FORCE_RECLONE` variables

## Behavior

### Normal Flow

1. Parse plugin spec (expand shorthand, extract ref, mode prefix)
2. Determine local cache path
3. Check if already cloned
4. If exists and not `PULSAR_FORCE_RECLONE`: Skip with message
5. If exists and `PULSAR_FORCE_RECLONE`: Remove and re-clone
6. Execute `git clone` to cache directory
7. If `@ref` specified: `git checkout ref`
8. Report success

### Parallel Execution

- Multiple plugin-spec arguments clone in parallel
- Bounded by CPU core count
- Each clone job runs in background (`&`)
- Main function waits for all jobs to complete
- Aggregate results and report

### Error Handling

- **Network failure**: Warn, skip plugin, continue
- **Invalid repository**: Warn, skip plugin, continue
- **Invalid ref**: Warn after clone, report but don't fail entire operation
- **Disk full**: Error, may abort operation
- **Permission denied**: Error, skip plugin

## Examples

### Basic Clone

```zsh
$ plugin-clone zsh-users/zsh-autosuggestions
📦 Cloning zsh-users/zsh-autosuggestions...
✅ Cloned zsh-users/zsh-autosuggestions
```

### Multiple Plugins (Parallel)

```zsh
$ plugin-clone zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting
📦 Cloning zsh-users/zsh-autosuggestions...
📦 Cloning zsh-users/zsh-syntax-highlighting...
✅ Cloned zsh-users/zsh-autosuggestions
✅ Cloned zsh-users/zsh-syntax-highlighting
```

### Version Pinning

```zsh
$ plugin-clone zsh-users/zsh-autosuggestions@v0.7.0
📦 Cloning zsh-users/zsh-autosuggestions...
🔒 Checking out ref: v0.7.0
✅ Cloned zsh-users/zsh-autosuggestions@v0.7.0
```

### Already Cloned

```zsh
$ plugin-clone zsh-users/zsh-autosuggestions
⏭️  zsh-users/zsh-autosuggestions already cloned (use PULSAR_FORCE_RECLONE=1 to re-clone)
```

### Clone Failure

```zsh
$ plugin-clone invalid-user/invalid-repo
📦 Cloning invalid-user/invalid-repo...
❌ Failed to clone invalid-user/invalid-repo: repository not found
```

## Dependencies

### External Commands

- `git` (required): For repository cloning
- `nproc` (optional): For determining CPU core count (falls back to 4)

### Zsh Builtins

- Background jobs (`&`)
- `wait` command
- Parameter expansion

### Internal Functions

- `pulsar__expand_shorthand`: Expand OMZP:: etc.
- `pulsar__cecho`: Colored output
- `warn`: Error message output

## Performance Characteristics

- **Sequential**: ~3 seconds per plugin (network-dependent)
- **Parallel (4 cores)**: ~3 seconds for 4 plugins
- **Bounded**: Max `nproc` concurrent clones
- **Network I/O bound**: CPU usage minimal

## Configuration

### Environment Variables Used

- `PULSAR_HOME`: Cache directory location (default: `$XDG_CACHE_HOME/pulsar`)
- `PULSAR_FORCE_RECLONE`: If set, remove and re-clone existing plugins
- `PULSAR_PROGRESS`: Control progress output (auto/1/0)
- `PULSAR_COLOR`: Control colored output (auto/1/0)

### Respects

- TTY detection for output formatting
- `NO_COLOR` environment variable (via `pulsar__color_on`)

## Idempotency

- **Without `PULSAR_FORCE_RECLONE`**: Idempotent (skips if exists)
- **With `PULSAR_FORCE_RECLONE`**: Not idempotent (always re-clones)

## Thread Safety

- Safe for concurrent execution from different shells
- Git handles repository-level locking
- Each plugin clones to unique directory (no conflicts)

## Testing

### Test Cases

1. Clone new plugin successfully
2. Clone multiple plugins in parallel
3. Skip already-cloned plugin
4. Force re-clone existing plugin
5. Handle invalid repository gracefully
6. Handle network failure gracefully
7. Pin to specific tag/branch/commit
8. Expand shorthand aliases correctly
9. Respect quiet mode (no TTY)
10. Respect NO_COLOR environment

### Validation

- Check directory exists after clone
- Verify `.git` directory present
- Confirm correct ref checked out (if pinned)
- Validate exit codes
- Verify error messages appear on stderr
