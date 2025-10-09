# API Contract: plugin-update

**Feature**: 002-pulsar-minimal-zsh  
**Function**: `plugin-update`  
**Purpose**: Update installed plugins to latest versions (respecting version pins)

## Signature

```zsh
plugin-update [plugin-spec...]
```

## Parameters

### plugin-spec (optional, variadic)

- **Type**: String
- **Format**: `[prefix:]user/repo[@ref][/subpath]`
- **Description**: Specific plugin(s) to update. If omitted, updates all plugins in `PULSAR_PLUGINS`
- **Examples**:
  - `plugin-update` (updates all)
  - `plugin-update zsh-users/zsh-autosuggestions`
  - `plugin-update OMZP::git OMZP::docker`

## Return Values

- **Exit Code 0**: All updates completed (success or gracefully handled failures)
- **Exit Code 1**: Critical failure (rare)

## Side Effects

### File System

- Modifies git repositories in `$PULSAR_HOME/repos/*/*`
- Executes `git pull` or `git fetch && git checkout` depending on pin status
- May download new commits from remote

### Network

- Fetches updates from GitHub (or other git hosts)
- Network I/O proportional to changes since last update

### Standard Output

- Progress messages for each plugin being updated
- Success messages with update summary
- "Already up-to-date" messages for current plugins

### Standard Error

- Error messages for failed updates
- Warning messages for detached HEAD, conflicts, etc.

## Behavior

### Normal Flow

1. Determine plugin list:
   - If arguments provided: Use specified plugins
   - If no arguments: Use `PULSAR_PLUGINS` array
2. Expand shorthand aliases (OMZP::, etc.)
3. For each plugin (in parallel):
   - Determine local cache path
   - Check if plugin is cloned (skip if not)
   - Change to plugin directory
   - Parse version pinning:
     - **Tag pinned** (`@v1.0.0`): Skip update (tags are immutable)
     - **Branch pinned** (`@develop`): `git fetch && git checkout branch`
     - **Commit pinned** (`@abc123`): Skip update (specific commit)
     - **Unpinned**: `git pull` (update to latest on current branch)
   - Report success or failure
4. Wait for all parallel updates to complete
5. Display summary (updated count, failed count, skipped count)

### Parallel Execution

- Updates multiple plugins concurrently
- Bounded by CPU core count
- Each update job runs in background
- Main function waits for all to complete
- Aggregate results and report summary

### Version Pin Handling

#### Unpinned Plugin

```zsh
# Spec: zsh-users/zsh-autosuggestions
# Action: git pull
# Result: Updates to latest commit on current branch
```

#### Tag Pinned

```zsh
# Spec: zsh-users/zsh-autosuggestions@v0.7.0
# Action: None (skip)
# Result: Stays at v0.7.0 (tags are immutable)
# Message: "⏭️ Skipping (pinned to tag v0.7.0)"
```

#### Branch Pinned

```zsh
# Spec: zsh-users/zsh-autosuggestions@develop
# Action: git fetch origin && git checkout develop && git pull
# Result: Updates to latest commit on develop branch
```

#### Commit Pinned

```zsh
# Spec: zsh-users/zsh-autosuggestions@abc123def
# Action: None (skip)
# Result: Stays at specific commit
# Message: "⏭️ Skipping (pinned to commit abc123def)"
```

## Examples

### Update All Plugins

```zsh
$ plugin-update
🔄 Updating zsh-users/zsh-autosuggestions...
🔄 Updating zsh-users/zsh-syntax-highlighting...
🔄 Updating OMZP::git...
✅ Updated zsh-users/zsh-autosuggestions (3 commits)
✅ Updated zsh-users/zsh-syntax-highlighting (1 commit)
✅ OMZP::git already up-to-date
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: 2 updated, 1 up-to-date, 0 failed
```

### Update Specific Plugin

```zsh
$ plugin-update zsh-users/zsh-autosuggestions
🔄 Updating zsh-users/zsh-autosuggestions...
✅ Updated zsh-users/zsh-autosuggestions (5 commits)
```

### Update Multiple Specific Plugins

```zsh
$ plugin-update OMZP::git OMZP::docker OMZP::kubectl
🔄 Updating OMZP::git...
🔄 Updating OMZP::docker...
🔄 Updating OMZP::kubectl...
✅ Updated OMZP::git (2 commits)
✅ OMZP::docker already up-to-date
✅ Updated OMZP::kubectl (1 commit)
```

### Plugin Pinned to Tag

```zsh
$ plugin-update zsh-users/zsh-autosuggestions@v0.7.0
⏭️  Skipping zsh-users/zsh-autosuggestions (pinned to tag v0.7.0)
```

### Plugin Not Cloned

```zsh
$ plugin-update some-user/not-cloned-plugin
⚠️  Plugin some-user/not-cloned-plugin not found in cache
   Run: plugin-clone some-user/not-cloned-plugin
```

### Update with Failure

```zsh
$ plugin-update zsh-users/zsh-autosuggestions user/broken-plugin
🔄 Updating zsh-users/zsh-autosuggestions...
🔄 Updating user/broken-plugin...
✅ Updated zsh-users/zsh-autosuggestions
❌ Failed to update user/broken-plugin: detached HEAD state
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: 1 updated, 0 up-to-date, 1 failed
```

## Dependencies

### External Commands

- `git` (required): For repository operations
- `nproc` (optional): For determining CPU core count

### Zsh Builtins

- Background jobs (`&`)
- `wait` command
- `cd` for directory navigation
- Parameter expansion

### Internal Functions

- `pulsar__expand_shorthand`: Shorthand expansion
- `pulsar__parse_version_ref`: Extract version ref from spec
- `pulsar__cecho`: Colored output
- `warn`: Warning messages
- `error`: Error messages

## Performance Characteristics

- **Sequential**: ~2 seconds per plugin (network-dependent)
- **Parallel (4 cores)**: ~2 seconds for 4 plugins
- **Already up-to-date**: <1 second per plugin (fast-forward check)
- **Network bound**: Depends on remote repository size and network speed
- **Bounded**: Max `nproc` concurrent updates

## Configuration

### Environment Variables Used

- `PULSAR_HOME`: Cache directory location
- `PULSAR_PLUGINS`: Default plugin list (if no args)
- `PULSAR_PROGRESS`: Control progress output
- `PULSAR_COLOR`: Control colored output

### Respects

- TTY detection for output formatting
- `NO_COLOR` environment variable
- Git configuration (credentials, proxies, etc.)

## Error Handling

### Common Errors

#### Detached HEAD State

```text
❌ Failed to update: repository is in detached HEAD state
   Fix: cd $PULSAR_HOME/repos/user/repo && git checkout main
```

#### Local Modifications

```text
❌ Failed to update: uncommitted changes
   Fix: cd $PULSAR_HOME/repos/user/repo && git stash
```

#### Network Failure

```text
❌ Failed to update: network timeout
   Retry when network is available
```

#### Invalid Branch

```text
❌ Failed to update: branch 'develop' does not exist
   Check plugin spec: user/repo@develop
```

### Error Handling Strategy

- Continue updating other plugins on error
- Report all errors at end with context
- Provide actionable fix instructions
- No automatic conflict resolution (user intervention required)

## Update Detection

### Comparison Method

- Uses `git rev-parse HEAD` before and after update
- Counts commits between old and new HEAD
- Reports commit count in success message

### Already Up-to-Date

- Git reports "Already up-to-date" or "Current branch X is up to date"
- No changes to working tree
- Reported as success with zero commits

## Idempotency

- Safe to run multiple times
- No-op if already up-to-date
- Respects git state (won't re-download if current)

## Thread Safety

- Multiple shells can run `plugin-update` concurrently
- Git handles repository-level locking
- Each update process isolated to its own directory

## Post-Update Actions

### Automatic

- No automatic sourcing (requires shell restart or manual re-source)
- No automatic recompilation (user must run `plugin-compile` if desired)

### User Actions After Update

1. **Restart shell**: New code takes effect
2. **Or re-source**: `source ~/.zshrc` (may have side effects)
3. **Or re-compile**: `plugin-compile` (if using compilation)

## Testing

### Test Cases

1. Update unpinned plugin successfully
2. Update multiple plugins in parallel
3. Skip tag-pinned plugin
4. Update branch-pinned plugin
5. Skip commit-pinned plugin
6. Handle plugin not cloned
7. Handle detached HEAD gracefully
8. Handle local modifications
9. Handle network failure
10. Report correct commit counts
11. Display accurate summary
12. Continue after individual plugin failure
13. Expand shorthand aliases
14. Update all plugins when no args
15. Update specific plugins when args provided

### Validation

- Verify HEAD changed after update (if updates available)
- Check commit count accuracy
- Validate error messages on stderr
- Confirm summary counts match actual results
- Verify parallel execution (timing tests)
- Check no updates for pinned tags
- Confirm branch checkout for pinned branches
