# Feature Specification: Minimal Zsh Plugin Manager (Pulsar)

**Feature Branch**: `001-we-are-creating`
**Created**: 2025-10-07
**Status**: Draft
**Input**: User description: "We are creating a zsh plugin manager based on mattmc3/zsh_unplugged, which is an antidote lite like manager ... made by the same person who made antidote,antigen, etc. It should be minimal, KISS, and fast."

## Clarifications

### Session 2025-10-07

- Q: How should Pulsar support oh-my-zsh plugins? → A: Use zinit-style mechanism allowing users to reference OMZ plugins from ohmyzsh/ohmyzsh repo with subdirectory paths (e.g., `ohmyzsh/ohmyzsh/plugins/git`)
- Q: When a plugin loading error occurs, what should happen? → A: Warn and continue - Display informative warning message showing which plugin failed, then proceed with remaining plugins (similar to zinit behavior)
- Q: When multiple plugins define the same command or completion, how should Pulsar handle it? → A: Hybrid approach - Detect conflicts during startup with warning message, let Zsh handle naturally (last wins), provide separate `pulsar-check-conflicts` command for review and resolution
- Q: Should the installer automatically backup the user's `.zshrc` before modifying it? → A: Always backup - Create `.zshrc.backup.TIMESTAMP` before any changes for maximum safety
- Q: What does "plugin manager overhead" mean for performance measurement? → A: Manager initialization only (cache check, array processing, parallel spawn setup) - excludes actual plugin sourcing time. Measured as time delta between Pulsar entry point and first plugin source call. Target: <50ms for the manager infrastructure itself.
- Q: What is a "plugin spec"? → A: A string identifying a plugin source. Formats: `user/repo` (GitHub shorthand), `user/repo@v1.0` (version pin), `user/repo/subdir/path` (subdirectory like OMZ), `/abs/path` (local plugin). Used consistently in plugin arrays and manual functions.
- Q: Do progress indicators conflict with the <50ms overhead target? → A: No - Progress indicators only appear for long-running operations (>1 second duration) like initial cloning or updates. The <50ms overhead target applies to manager initialization and cached plugin loading, which happen without progress display.
- Q: What happens when `plugin-update` encounters a version-pinned plugin? → A: Skip silently during batch update, report in summary as "N pinned (not updated)". Users can manually update pins by changing the version specifier in their plugin declaration.
- Q: In what order are plugins loaded within each array? → A: Plugins load in array declaration order (top to bottom as declared in .zshrc). This ensures deterministic, predictable loading sequence for dependency management.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Plugin Management (Priority: P1)

Users need to clone, load, and manage Zsh plugins from GitHub repositories with minimal configuration and maximum speed.

**Why this priority**: This is the core value proposition. Without basic plugin management, nothing else matters. This delivers immediate value and forms the foundation for all other features.

**Independent Test**: Can be fully tested by installing Pulsar, declaring 2-3 plugins in `.zshrc`, and verifying they clone in parallel and load correctly on shell startup.

**Acceptance Scenarios**:

1. **Given** a fresh Zsh installation, **When** user runs Pulsar installer, **Then** `.zshrc` is backed up with timestamp before modifications
2. **Given** user installs Pulsar and declares plugins in `.zshrc`, **When** shell starts, **Then** plugins clone in parallel on first shell startup
3. **Given** plugins are already cloned, **When** user opens a new shell, **Then** plugins load instantly without re-cloning
4. **Given** user declares `PULSAR_PLUGINS=(user/repo another/plugin)`, **When** shell starts, **Then** init files are automatically discovered and sourced
5. **Given** a plugin repository URL, **When** user specifies it in plugin arrays, **Then** it clones to cache directory and becomes available
6. **Given** plugins are loaded, **When** user checks shell startup time, **Then** overhead is minimal (< 50ms for manager itself)

---

### User Story 2 - Flexible Plugin Loading (Priority: P2)

Users need to load plugins in different modes: regular sourcing, PATH addition, or fpath addition for completions and prompts, including oh-my-zsh plugins without installing oh-my-zsh.

**Why this priority**: Different plugins serve different purposes. Completions need fpath, CLI tools need PATH, and scripts need sourcing. This enables proper integration of all plugin types. Supporting OMZ plugins expands the ecosystem dramatically without requiring OMZ installation.

**Independent Test**: Can be tested by configuring one plugin of each type (PULSAR_PLUGINS, PULSAR_PATH, PULSAR_FPATH) and verifying each behaves correctly (sourced, on PATH, or in fpath). Also test loading an OMZ plugin using subdirectory path syntax.

**Acceptance Scenarios**:

1. **Given** `PULSAR_PLUGINS` array contains plugin names, **When** shell starts, **Then** plugin init files are sourced
2. **Given** `PULSAR_PATH` array contains tool plugins, **When** shell starts, **Then** plugins are added to PATH (using bin/ directory if present)
3. **Given** `PULSAR_FPATH` array contains completion plugins, **When** shell starts, **Then** plugins are added to fpath for completions/prompts
4. **Given** user calls `plugin-load --kind path user/repo`, **When** command executes, **Then** plugin is added to PATH without sourcing
5. **Given** user has multiple loading modes, **When** declaring the same plugin, **Then** appropriate mode is respected
6. **Given** user declares `PULSAR_PLUGINS=(ohmyzsh/ohmyzsh/plugins/git)`, **When** shell starts, **Then** OMZ git plugin loads correctly from subdirectory

---

### User Story 3 - Plugin Updates and Compilation (Priority: P3)

Users need to update all installed plugins and optionally compile init files for faster subsequent loads.

**Why this priority**: Keeping plugins current is important for bug fixes and features, but less critical than initial setup. Compilation is a performance optimization that can be applied after basic functionality works.

**Independent Test**: Can be tested by installing plugins, running `plugin-update`, verifying git pulls succeed, then running `plugin-compile` and verifying `.zwc` files are created.

**Acceptance Scenarios**:

1. **Given** plugins are cloned, **When** user runs `plugin-update`, **Then** all plugins git pull latest changes
2. **Given** plugins have updates available, **When** update completes, **Then** user sees summary of updated plugins
3. **Given** plugins are loaded, **When** user runs `plugin-compile`, **Then** init files are compiled to `.zwc` bytecode
4. **Given** compiled files exist, **When** shell loads plugins, **Then** compiled versions are used for faster sourcing
4. **Given** update or compile fails for one plugin, **When** command runs, **Then** other plugins continue processing
5. **Given** a plugin has errors, **When** loading, **Then** user sees informative warning message and remaining plugins load successfully

---

### User Story 4 - Manual Plugin Control (Priority: P4)

Power users need direct control via functions: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile` for manual workflows.

**Why this priority**: Manual control enables advanced use cases like conditional loading, deferred loading, or custom workflows. Essential for power users but not required for basic functionality.

**Independent Test**: Can be tested by calling functions directly in command line: `plugin-clone user/repo`, `plugin-load user/repo`, verify behavior without declarative arrays.

**Acceptance Scenarios**:

1. **Given** user calls `plugin-clone user/repo`, **When** command executes, **Then** plugin clones from GitHub to cache directory
2. **Given** user calls `plugin-load user/repo`, **When** command executes, **Then** plugin's init file is sourced
3. **Given** user specifies `plugin-clone user/repo@v1.2.3`, **When** cloning, **Then** specific tag/branch/commit is checked out
4. **Given** user calls functions manually, **When** executed, **Then** they work independently of declarative arrays
5. **Given** user combines manual and declarative approaches, **When** shell starts, **Then** both methods work without conflicts
6. **Given** multiple plugins define the same command, **When** user runs `pulsar-check-conflicts`, **Then** all conflicts are listed with source plugins

---

### User Story 5 - Self-Update and Version Management (Priority: P5)

Users need to keep Pulsar itself updated and receive notifications about new versions.

**Why this priority**: Self-maintenance is valuable but not essential for core functionality. Users can manually update if needed, making this a convenience feature.

**Independent Test**: Can be tested by running `pulsar-self-update`, verifying it fetches latest code, and checking that update notifications appear after configured intervals.

**Acceptance Scenarios**:

1. **Given** new Pulsar version is available, **When** configured interval passes, **Then** user sees update notification
2. **Given** user runs `pulsar-self-update`, **When** command executes, **Then** latest `pulsar.zsh` is fetched and re-sourced
3. **Given** user runs `pulsar-update`, **When** command executes, **Then** both Pulsar and all plugins are updated
4. **Given** update check succeeds, **When** notification displays, **Then** user sees version number and optional release notes
5. **Given** user sets `PULSAR_UPDATE_CHANNEL=unstable`, **When** checking for updates, **Then** main branch commits are checked instead of releases

---

### Edge Cases

- What happens when a plugin repository doesn't exist or is private (network/auth errors)? → Display warning with plugin name and error, continue with remaining plugins
- How does the system handle plugins with non-standard init file names or structures? → Display warning about missing init file, skip that plugin, continue with others
- What happens when multiple plugins provide the same command or completion? → Display warning during startup, last loaded plugin wins (Zsh default), user can run `pulsar-check-conflicts` for detailed review
- How does Pulsar behave when git is not available or configured?
- What happens when cache directory is deleted or corrupted?
- How does Pulsar handle ZDOTDIR configurations (user has custom config location)?
- What happens when a plugin's init file has syntax errors? → Display warning with plugin name and line number (if available), skip that plugin, continue with others
- How does parallel cloning handle rate limiting or network failures? → Display warning for failed clones, continue with successful ones
- What happens when a plugin is removed from arrays but still exists in cache?
- How does the system behave with 100+ plugins (performance degradation)?

### Recovery Flows

When errors occur, Pulsar provides recovery mechanisms:

- **Cache corruption/deletion**: Re-clone affected plugins automatically on next shell startup (cache acts as optimization, not critical state)
- **Failed plugin clone**: Use `plugin-clone <spec>` to retry manually, or use `plugin-clone <spec> --force` (via FR-020) to force re-clone
- **Installation errors**: Restore from timestamped `.zshrc.backup.YYYYMMDD-HHMMSS` file created by installer (FR-018a)
- **Plugin syntax errors**: Remove problematic plugin from arrays in `.zshrc`, restart shell (warning messages identify the failing plugin)
- **Git failures during update**: Individual plugin failures don't block others; review warnings and retry specific plugins with `plugin-update <spec>`
- **Broken dependencies**: Use `pulsar-check-conflicts` to identify conflicting plugins, adjust load order or remove conflicts

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST clone plugins from GitHub repositories in parallel to minimize wait time
- **FR-002**: System MUST automatically discover init files using precedence order: 1) `{name}.plugin.zsh`, 2) `{name}.zsh`, 3) `init.zsh`, 4) first `*.plugin.zsh` match (glob), 5) first `*.zsh` match (glob), where `{name}` is the plugin directory name
- **FR-003**: System MUST cache cloned plugins to avoid re-cloning on subsequent shell startups
- **FR-004**: System MUST support declarative plugin loading via arrays (`PULSAR_PLUGINS`, `PULSAR_PATH`, `PULSAR_FPATH`)
- **FR-005**: System MUST provide manual control functions (`plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`)
- **FR-005a**: System MUST provide `pulsar-check-conflicts` command to detect and display plugin conflicts (duplicate commands/completions)
- **FR-005b**: System MUST detect command/completion conflicts during plugin loading and display informative warnings
- **FR-006**: System MUST support pinning plugins to specific tags, branches, or commits
- **FR-007**: System MUST compile plugin init files to Zsh bytecode for performance optimization
- **FR-008**: System MUST update all plugins with a single command
- **FR-009**: System MUST respect XDG Base Directory specification for cache location (`XDG_CACHE_HOME`)
- **FR-010**: System MUST handle ZDOTDIR configurations gracefully (custom config directories)
- **FR-011**: System MUST provide progress indicators for long-running operations (cloning, updating) using format `[n/total] plugin-name` updated per completion
- **FR-012**: System MUST work with only Zsh and git as dependencies (no Ruby, Python, or other runtimes)
- **FR-013**: System MUST check for and notify about Pulsar updates on stable and unstable channels
- **FR-014**: System MUST allow users to disable update notifications and auto-run behavior
- **FR-015**: System MUST support local plugin paths in addition to GitHub repositories
- **FR-015a**: System MUST support oh-my-zsh plugins using subdirectory paths (e.g., `ohmyzsh/ohmyzsh/plugins/git`) similar to zinit's mechanism
- **FR-015b**: System MUST automatically discover init files within OMZ plugin subdirectories following OMZ naming conventions
- **FR-016**: System MUST provide colored output with auto-detection and manual override
- **FR-017**: System MUST differentiate between interactive and non-interactive shells for output behavior
- **FR-017a**: System MUST display informative warning messages when plugin loading fails, identifying the specific plugin and reason
- **FR-017b**: System MUST continue loading remaining plugins after a plugin failure rather than halting initialization
- **FR-018**: System MUST include an installer script that sets up bootstrap and modifies `.zshrc`
- **FR-018a**: Installer MUST create timestamped backup of `.zshrc` (format: `.zshrc.backup.YYYYMMDD-HHMMSS`) before any modifications
- **FR-018b**: Installer MUST verify backup was created successfully before proceeding with modifications
- **FR-019**: System MUST create VS Code shim for custom ZDOTDIR configurations
- **FR-020**: System MUST support force re-cloning of plugins when requested
- **FR-021**: All shell functions MUST return 0 on success, non-zero on failure, and propagate errors correctly to enable proper error handling in calling contexts
- **FR-022**: All user-facing manual functions MUST provide usage help via `--help` flag showing syntax, parameters, and examples

### Key Entities

- **Plugin**: A Zsh script repository from GitHub or local path with discoverable init files
- **Plugin Spec**: A string identifying a plugin source (see Clarifications for format details). Used consistently throughout arrays and manual functions. Formats: `user/repo` (GitHub), `user/repo@v1.0` (version pin), `user/repo/subdir/path` (OMZ subdirectory), `/abs/path` (local)
- **Plugin Cache**: Directory structure at `${XDG_CACHE_HOME:-$HOME/.cache}/pulsar` where cloned plugins are stored
- **Plugin Array**: User-declared arrays (`PULSAR_PLUGINS`, `PULSAR_PATH`, `PULSAR_FPATH`) containing plugin specs and specifying loading mode
- **Init File**: The main executable Zsh script within a plugin (plugin.zsh, init.zsh, etc.) that gets sourced or used
- **Bootstrap File**: The core Pulsar loader script at `$ZSH/lib/pulsar-bootstrap.zsh` that initializes the system
- **Update Channel**: Configuration setting (stable/unstable/off) that determines version checking behavior

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can install Pulsar and start using plugins within 5 minutes (including reading Quick Start)
- **SC-002**: Plugin manager adds less than 50ms overhead to shell startup time (measured with `zsh-bench`)
- **SC-003**: System successfully clones and loads 10 plugins in under 10 seconds on first run
- **SC-004**: System handles 100+ plugins without degrading startup time beyond 100ms
- **SC-005**: Plugin updates complete within 30 seconds for typical configurations (10-20 plugins)
- **SC-006**: 95% of common plugin repositories work without manual configuration (automatic init file discovery)
- **SC-006a**: All popular oh-my-zsh plugins (git, docker, kubectl, etc.) load successfully using subdirectory syntax
- **SC-007**: Documentation examples work exactly as written for new users (copy-paste success rate)
- **SC-008**: Parallel cloning is 3x faster than serial cloning for 10+ plugins
- **SC-009**: Users can uninstall Pulsar completely by removing 3 items (block in .zshrc, bootstrap file, cache directory)
- **SC-009a**: Users can restore original `.zshrc` from installer backup if installation causes issues
- **SC-010**: System operates identically whether ZDOTDIR is set or unset (configuration portability)

## Assumptions

- **ASM-001**: Users have Zsh 5.8+ installed (reasonable modern requirement)
- **ASM-002**: Users have git available in PATH (standard development tool)
- **ASM-003**: Users have network access to GitHub (required for cloning public repos)
- **ASM-004**: Plugin repositories follow common Zsh plugin structure conventions
- **ASM-005**: Users are comfortable editing `.zshrc` text file (basic shell knowledge)
- **ASM-006**: curl is available for installer and self-update (optional, degrades gracefully)
- **ASM-007**: Python 3 is available for release notes display (optional enhancement)
- **ASM-008**: Standard terminal capabilities for color output (falls back to plain text)
- **ASM-009**: File system supports standard Unix permissions and symbolic links
- **ASM-010**: GitHub's HTTPS clone URLs remain stable (<https://github.com/owner/repo>)
- **ASM-011**: Typical plugin cache size is ~100MB for 20 plugins; no automatic cache cleanup is performed (users can manually delete cache directory if needed)

## Constraints

- **CON-001**: MUST use only native Zsh and git (no external language runtimes)
- **CON-002**: MUST maintain compatibility with Zsh 5.8+
- **CON-003**: MUST keep codebase under 1000 lines for maintainability (KISS principle)
- **CON-004**: MUST avoid requiring root/sudo for installation or operation
- **CON-005**: MUST work on Linux, macOS, and WSL environments
- **CON-006**: MUST NOT modify user's existing plugin configurations (safe installation)
- **CON-007**: MUST NOT set ZDOTDIR (only respect existing setting)
- **CON-008**: MUST provide graceful fallbacks when optional dependencies are missing
- **CON-009**: MUST maintain backward compatibility with existing Pulsar configurations
- **CON-010**: MUST be faster than antidote/antigen alternatives (benchmark requirement)
