# Research: Minimal Zsh Plugin Manager (Pulsar)

**Feature**: Pulsar - Minimal Zsh Plugin Manager
**Date**: 2025-10-07
**Purpose**: Research technical decisions for implementing a fast, KISS-principle plugin manager

## Overview

This document captures research decisions for building Pulsar, ensuring the implementation stays simple, feature-rich, and idiomatic while maintaining sub-50ms startup overhead.

---

## Decision 1: Pure Zsh Implementation Strategy

**Decision**: Implement entirely in Zsh without external language runtimes

**Rationale**:

- Eliminates dependencies (no Python, Ruby, Node.js required)
- Reduces installation complexity and potential failure points
- Ensures consistent behavior across platforms
- Leverages Zsh's built-in capabilities (associative arrays, process substitution, coprocesses)
- Aligns with KISS principle and constraint CON-001

**Alternatives Considered**:

- **Hybrid Zsh + Python**: Would enable richer data structures and easier async, but violates "minimal" principle and adds dependency
- **Go/Rust compiled binary**: Would be fast but requires compilation, cross-platform binaries, and violates simplicity
- **Zsh + external tools (jq, etc.)**: Would add parsing power but increases dependencies

**Implementation Notes**:

- Use Zsh 5.8+ features: associative arrays for plugin metadata, `zargs` for parallel operations
- Leverage `coproc` for background git operations during parallel cloning
- Use parameter expansion for string manipulation (avoid external tools like sed/awk)
- Implement ini-style parsing for plugin version pinning using pure Zsh

---

## Decision 2: Parallel Cloning Strategy

**Decision**: Use Zsh background jobs with `wait` for parallel git cloning

**Rationale**:

- Zsh native job control (`&` and `wait`) provides simple parallelism
- No external tools required (GNU parallel, xargs -P)
- Bounded parallelism prevents resource exhaustion (limit to CPU cores or configurable max)
- Allows per-plugin error tracking while maintaining overall progress

**Alternatives Considered**:

- **Sequential cloning**: Simple but too slow for 10+ plugins
- **GNU parallel**: Not universally available, adds dependency
- **xargs -P**: Platform differences (BSD vs GNU), less control over error handling

**Implementation Approach**:

```zsh
_pulsar_parallel_clone() {
  local max_jobs=${PULSAR_MAX_JOBS:-$(nproc 2>/dev/null || echo 4)}
  local -a pids=()
  local -A failed=()

  for plugin in "$@"; do
    while (( ${#${(v)jobstates:#*=running}} >= max_jobs )); do
      sleep 0.1
    done

    _pulsar_clone_one "$plugin" &
    pids+=($!)
  done

  for pid in $pids; do
    wait $pid || failed[$pid]=1
  done

  return ${#failed}
}
```

**Performance Target**: 10 plugins in < 10 seconds (3x faster than serial)

---

## Decision 3: Init File Discovery Pattern

**Decision**: Use ordered pattern matching with glob for automatic init file discovery

**Rationale**:

- Most plugins follow conventions: `plugin.zsh`, `{name}.plugin.zsh`, `init.zsh`, `{name}.zsh`
- Glob patterns are Zsh-native and fast
- Ordered search respects common precedence
- Handles OMZ plugins (often just `{name}.plugin.zsh`)

**Alternatives Considered**:

- **Manifest file requirement**: Too rigid, breaks existing plugins
- **Search all *.zsh files**: Too broad, could source unintended files
- **User-specified init file**: Defeats "automatic" discovery, but keep as fallback

**Discovery Order**:

1. `{plugin-name}.plugin.zsh` (most specific, OMZ standard)
2. `{plugin-name}.zsh` (common alternative)
3. `init.zsh` (generic convention)
4. First `*.plugin.zsh` found (fallback for OMZ monorepo subdirs)
5. First `*.zsh` found (last resort)

**Implementation**:

```zsh
_pulsar_find_init() {
  local plugin_dir=$1
  local plugin_name=$(basename "$plugin_dir")
  local -a candidates=(
    "$plugin_dir/$plugin_name.plugin.zsh"
    "$plugin_dir/$plugin_name.zsh"
    "$plugin_dir/init.zsh"
    "$plugin_dir"/*.plugin.zsh(N[1])
    "$plugin_dir"/*.zsh(N[1])
  )

  for init in $candidates; do
    [[ -f $init ]] && { echo "$init"; return 0 }
  done
  return 1
}
```

---

## Decision 4: OMZ Plugin Subdirectory Support

**Decision**: Parse repo/subdir syntax and clone full repo, load from subdirectory

**Rationale**:

- Matches zinit's approach (proven UX)
- Allows loading OMZ plugins without OMZ installation
- Single clone of ohmyzsh/ohmyzsh repo serves multiple plugins
- Maintains cache efficiency (don't clone same repo multiple times)

**Alternatives Considered**:

- **Sparse checkout**: Complex, not universally supported, overkill for small plugins
- **Submodule approach**: Requires repo modification, doesn't work with upstream repos
- **Manual copy**: Requires user intervention, defeats automation

**Parsing Strategy**:

```zsh
# Input: ohmyzsh/ohmyzsh/plugins/git
# Output: repo=ohmyzsh/ohmyzsh subdir=plugins/git

_pulsar_parse_plugin_spec() {
  local spec=$1
  local repo subdir

  if [[ $spec == */*/* ]]; then
    # Contains subdirectory
    repo="${spec%/*}"           # ohmyzsh/ohmyzsh
    subdir="${spec##*/}"         # plugins/git
  else
    repo=$spec
    subdir=""
  fi

  echo "repo=$repo"
  [[ -n $subdir ]] && echo "subdir=$subdir"
}
```

**Cache Structure**:

```text
$PULSAR_HOME/
└── ohmyzsh--ohmyzsh/        # Full repo clone
    └── plugins/
        ├── git/             # Load from here
        ├── docker/          # Or here
        └── kubectl/         # Or here
```

**Success Criteria**: SC-006a - All popular OMZ plugins load successfully

---

## Decision 5: Error Handling and Warning Strategy

**Decision**: Warn-and-continue with structured error messages, optional debug mode

**Rationale**:

- Never block shell startup (user can still work)
- Informative warnings help debugging without overwhelming
- Similar to zinit behavior (proven UX)
- Graceful degradation aligns with ease-of-use focus

**Alternatives Considered**:

- **Silent failure**: Hides problems, frustrates users
- **Stop on error**: Blocks shell startup, poor UX
- **Log-only**: Users won't check logs proactively

**Error Message Format**:

```zsh
_pulsar_warn() {
  local plugin=$1 reason=$2
  [[ $PULSAR_QUIET == 1 ]] && return

  print -P "%F{yellow}[pulsar]%f Plugin %F{cyan}${plugin}%f failed: ${reason}" >&2
}

_pulsar_debug() {
  [[ $PULSAR_DEBUG == 1 ]] || return
  print -P "%F{blue}[pulsar:debug]%f $*" >&2
}
```

**Examples**:

- `[pulsar] Plugin 'user/repo' failed: repository not found`
- `[pulsar] Plugin 'user/plugin' failed: no init file discovered`
- `[pulsar:debug] Detected conflict: command 'kubectl' from both 'plugin-a' and 'plugin-b'`

**Environment Variables**:

- `PULSAR_QUIET=1`: Suppress warnings (not recommended)
- `PULSAR_DEBUG=1`: Show detailed debugging info

---

## Decision 6: Plugin Conflict Detection

**Decision**: Track command sources, warn on conflicts, provide diagnostic command

**Rationale**:

- Early detection prevents confusion
- Diagnostic command helps users understand plugin interactions
- No startup blocking (warnings only during load)
- Respects Zsh's last-wins default behavior

**Alternatives Considered**:

- **Block on conflict**: Too disruptive, some conflicts are intentional (override)
- **No detection**: Users wonder why commands don't work as expected
- **Automatic resolution**: Too opinionated, may break intentional overrides

**Implementation Approach**:

```zsh
typeset -gA _PULSAR_COMMAND_SOURCES  # command -> plugin

_pulsar_track_commands() {
  local plugin=$1 plugin_dir=$2
  local -a new_commands

  # Before loading
  local -a before=(${(k)commands})

  # Load plugin
  source "$plugin_dir/init.zsh"

  # After loading
  local -a after=(${(k)commands})
  new_commands=(${after:|before})

  for cmd in $new_commands; do
    if [[ -n ${_PULSAR_COMMAND_SOURCES[$cmd]} ]]; then
      _pulsar_warn "$plugin" "command '$cmd' conflicts with ${_PULSAR_COMMAND_SOURCES[$cmd]}"
    fi
    _PULSAR_COMMAND_SOURCES[$cmd]=$plugin
  done
}
```

**Diagnostic Command**:

```zsh
pulsar-check-conflicts() {
  print "Plugin Command Conflicts:"
  print "========================="

  local -A conflicts
  for cmd source in ${(kv)_PULSAR_COMMAND_SOURCES}; do
    # Show commands provided by multiple plugins
  done
}
```

---

## Decision 7: Installer Safety (Backup Strategy)

**Decision**: Always create timestamped .zshrc backup before modification

**Rationale**:

- Maximum safety for users (can always rollback)
- Timestamped backups preserve history
- No interactive prompts (keeps one-liner simple)
- Aligns with ease-of-use and user safety priorities

**Alternatives Considered**:

- **Prompt user**: Breaks one-liner installer flow
- **Only if not in git**: Too clever, assumes git usage
- **No backup**: Risky, violates "ease of use"

**Backup Format**:

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp ~/.zshrc ~/.zshrc.backup.$TIMESTAMP
```

**Installer Flow**:

1. Check if Pulsar block already exists (skip if present)
2. Create backup: `.zshrc.backup.YYYYMMDD-HHMMSS`
3. Verify backup succeeded (fail if not)
4. Append Pulsar configuration block
5. Report backup location to user

**Success Message**:

```text
✓ Backup created: ~/.zshrc.backup.20251007-143022
✓ Pulsar configuration added to ~/.zshrc
✓ Restart your shell to activate
```

---

## Decision 8: Performance Optimization Strategy

**Decision**: Compiled scripts (.zwc), plugin caching, lazy loading support

**Rationale**:

- .zwc compilation reduces parse time (important for 100+ plugins)
- Caching eliminates unnecessary re-cloning
- Lazy loading defers non-critical plugins
- Meets <50ms overhead target

**Alternatives Considered**:

- **No compilation**: Simpler but slower, doesn't meet performance target
- **Always compile**: Too aggressive, compilation has overhead
- **Aggressive lazy loading**: Too complex, breaks expectations

**Compilation Strategy**:

```zsh
plugin-compile() {
  for init in $PULSAR_HOME/**/*.plugin.zsh $PULSAR_HOME/**/init.zsh; do
    zcompile "$init"
  done
}
```

**Load Preference**:

```zsh
# Prefer .zwc if newer than source
if [[ $init.zwc -nt $init ]]; then
  source $init.zwc
else
  source $init
fi
```

**Lazy Loading Support** (optional, for power users):

```zsh
# User can defer plugins
PULSAR_DEFER=(romkatv/zsh-defer)
plugin-load romkatv/zsh-defer  # Load deferrer first

# Then defer others
zsh-defer plugin-load heavy-plugin
```

---

## Decision 9: Configuration Variables Design

**Decision**: Prefix all config vars with `PULSAR_`, use XDG defaults, auto-detect where appropriate

**Rationale**:

- Clear namespace prevents conflicts
- XDG compliance is expected by modern tools
- Auto-detection reduces configuration burden
- Aligns with "easy to customize" goal

**Key Configuration Variables**:

| Variable | Default | Purpose |
|----------|---------|---------|
| `PULSAR_HOME` | `${XDG_CACHE_HOME:-$HOME/.cache}/pulsar` | Plugin cache location |
| `PULSAR_GITURL` | `https://github.com/` | Base URL for clones |
| `PULSAR_PLUGINS` | `()` | Plugins to source |
| `PULSAR_PATH` | `()` | Plugins to add to PATH |
| `PULSAR_FPATH` | `()` | Plugins to add to fpath |
| `PULSAR_PROGRESS` | `auto` | Show progress (`auto`/`1`/`0`) |
| `PULSAR_COLOR` | `auto` | Use color (`auto`/`1`/`0`) |
| `PULSAR_BANNER` | `auto` | Show banner (`auto`/`1`/`0`) |
| `PULSAR_UPDATE_CHANNEL` | `stable` | Update channel (`stable`/`unstable`/`off`) |
| `PULSAR_MAX_JOBS` | `$(nproc)` | Max parallel clones |
| `PULSAR_DEBUG` | `0` | Debug output |
| `PULSAR_QUIET` | `0` | Suppress warnings |

**Auto-Detection Logic**:

```zsh
# PULSAR_PROGRESS=auto
[[ -t 1 ]] && is_interactive=1 || is_interactive=0

# PULSAR_COLOR=auto
[[ -t 2 && -n $COLORTERM ]] && use_color=1 || use_color=0
```

---

## Decision 10: Test Strategy

**Decision**: Integration tests using Markdown format, performance benchmarks, manual testing guide

**Rationale**:

- Integration tests cover real workflows (install → load → update)
- Markdown tests are readable and self-documenting
- Performance benchmarks catch regressions
- Shell code is hard to unit test (integration tests more valuable)

**Test Organization**:

1. **Core Functionality** (`test-pulsar.md`): Clone, load, update, compile
2. **OMZ Compatibility** (`test-omz-plugins.md`): Subdirectory paths, OMZ plugin discovery
3. **Error Handling** (`test-error-handling.md`): Missing repos, syntax errors, network failures
4. **Installer** (`test-installer.md`): Backup creation, .zshrc modification, ZDOTDIR handling
5. **Conflicts** (`test-conflicts.md`): Command conflicts, diagnostic command
6. **Performance** (`test-performance.md`): Startup time, parallel cloning, scale (100+ plugins)

**Test Framework**: Custom runner using Zsh's testing capabilities + existing patterns from tests/run-clitests

**Coverage Target**: 80% critical paths (clone, load, update functions), 60% overall

---

## Decision 11: Idiomatic Zsh Patterns

**Decision**: Use Zsh idioms for clarity and reliability

**Rationale**:

- Parameter expansion over external tools (sed, awk, cut)
- Glob qualifiers for file filtering
- Associative arrays for metadata
- Process substitution for pipelines
- Proper quoting and array handling

**Key Idioms**:

```zsh
# Good: Zsh parameter expansion
repo="${spec%/*}"

# Avoid: External tool
repo=$(echo "$spec" | cut -d/ -f1-2)

# Good: Glob qualifiers
local init=(*.plugin.zsh(N[1]))  # First match, null if none

# Avoid: Manual loop with test
for f in *.plugin.zsh; do
  [[ -f $f ]] || continue
  init=$f
  break
done

# Good: Associative array
typeset -A plugin_metadata
plugin_metadata[$plugin]="version=1.2.3 status=loaded"

# Good: Process substitution
diff <(sort file1) <(sort file2)
```

**Conditional Design**:

- Use `[[` over `[` (Zsh-native, more features)
- Prefer `(( ))` for arithmetic
- Guard all array expansions: `"${array[@]}"`
- Use `${var:-default}` for defaults

---

## Implementation Checklist

- [ ] Core functions in pulsar.zsh (<1000 lines total)
- [ ] Parallel cloning with bounded concurrency
- [ ] Init file auto-discovery (5-pattern precedence)
- [ ] OMZ subdirectory path parsing
- [ ] Error handling with structured warnings
- [ ] Conflict detection and diagnostic command
- [ ] Installer with automatic backup
- [ ] Configuration variable defaults
- [ ] Compiled script support (.zwc)
- [ ] Integration test suite
- [ ] Performance benchmarks
- [ ] Documentation with examples

---

## Performance Targets Summary

| Metric | Target | Test Method |
|--------|--------|-------------|
| Startup overhead | < 50ms | zsh-bench |
| Parallel clone (10 plugins) | < 10s | time measurement |
| Plugin loading (100 plugins) | < 5min | scale test |
| Individual command | < 100ms | interactive feel |
| Test suite | < 5min | CI/CD acceptable |

---

## Next Steps

1. Implement core functions in pulsar.zsh following decisions above
2. Create installer script with backup logic
3. Write integration tests for each user story
4. Add performance benchmarks
5. Update documentation with examples
6. Validate against constitution requirements
