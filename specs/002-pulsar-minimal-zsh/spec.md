# Feature Specification: Pulsar - Minimal Zsh Plugin Manager

**Feature Branch**: `002-pulsar-minimal-zsh`
**Created**: 2025-10-08
**Status**: Implemented (Retrospective Documentation)
**Input**: User description: "Pulsar minimal Zsh plugin manager with Oh-My-Zsh/Prezto support, parallel operations, version pinning, self-update system, and comprehensive plugin management capabilities"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Plugin Management (Priority: P1)

A Zsh user wants to install and use community plugins without managing git repositories manually. They want a simple declarative configuration that automatically clones, loads, and caches plugins.

**Why this priority**: Core value proposition - enables basic plugin management which is the fundamental purpose of the tool.

**Independent Test**: User adds a plugin to their configuration array, sources pulsar.zsh, and the plugin is automatically cloned and loaded without manual intervention.

**Acceptance Scenarios**:

1. **Given** a fresh Zsh environment, **When** user declares `PULSAR_PLUGINS=(user/repo)` and sources pulsar.zsh, **Then** the plugin is cloned to cache directory and automatically loaded
2. **Given** a plugin already cached, **When** user starts a new shell session, **Then** the plugin loads instantly without re-cloning
3. **Given** multiple plugins in the array, **When** sourcing pulsar.zsh, **Then** all plugins are processed in parallel and loaded in declaration order
4. **Given** a plugin with multiple possible entry points, **When** loading the plugin, **Then** pulsar automatically discovers and sources the correct initialization file
5. **Given** a plugin that doesn't exist, **When** attempting to load, **Then** a clear error message is displayed and other plugins continue loading

---

### User Story 2 - Oh-My-Zsh Migration (Priority: P2)

An Oh-My-Zsh user wants to migrate to a minimal plugin manager without losing access to OMZ plugins, lib files, and themes. They want familiar shorthand syntax.

**Why this priority**: Addresses the largest user base (OMZ users) and reduces migration friction, making adoption viable.

**Independent Test**: User replaces oh-my-zsh with pulsar, uses OMZP:: syntax for plugins, and all OMZ functionality works identically.

**Acceptance Scenarios**:

1. **Given** an OMZ plugin name, **When** user declares `OMZP::git`, **Then** the ohmyzsh/ohmyzsh repo is cloned and plugins/git is loaded correctly
2. **Given** an OMZ lib file, **When** user declares `OMZL::completion`, **Then** lib/completion.zsh is sourced properly
3. **Given** an OMZ theme, **When** user declares `OMZT::robbyrussell`, **Then** the theme file is loaded and prompt appears correctly
4. **Given** plugins using `compdef`, **When** OMZ plugins load, **Then** completions initialize automatically without user intervention
5. **Given** mixed OMZ and regular plugins, **When** loading all plugins, **Then** both types work seamlessly together

---

### User Story 3 - Version Pinning and Stability (Priority: P2)

A user wants to pin plugins to specific versions (tags, branches, commits) to ensure reproducible environments and avoid breaking changes from upstream updates.

**Why this priority**: Critical for production stability and team collaboration where everyone needs identical plugin versions.

**Independent Test**: User pins a plugin to a specific tag, updates happen, and the plugin stays at that version until explicitly changed.

**Acceptance Scenarios**:

1. **Given** a plugin spec with `@v1.2.3`, **When** cloning the plugin, **Then** git checks out that specific tag
2. **Given** a plugin spec with `@develop`, **When** cloning the plugin, **Then** git checks out the develop branch
3. **Given** a plugin spec with commit SHA `@abc123`, **When** cloning the plugin, **Then** git checks out that specific commit
4. **Given** a pinned plugin, **When** running plugin-update, **Then** the plugin updates to the latest commit on that ref (tags stay fixed, branches pull latest)
5. **Given** invalid ref specification, **When** attempting to clone, **Then** a clear error message explains the problem

---

### User Story 4 - Plugin Updates and Maintenance (Priority: P3)

A user wants to keep their plugins up-to-date without manually updating each git repository. They want bulk updates with progress indication.

**Why this priority**: Maintenance efficiency - reduces ongoing overhead after initial setup.

**Independent Test**: User runs update command, all plugins fetch latest changes, and updates complete within reasonable time.

**Acceptance Scenarios**:

1. **Given** multiple installed plugins, **When** user runs `plugin-update`, **Then** all plugins update in parallel with progress indicators
2. **Given** a plugin with no updates available, **When** updating, **Then** user is informed it's already current
3. **Given** a plugin update fails (network issue), **When** updating all plugins, **Then** error is reported but other plugins continue updating
4. **Given** pinned plugins on branches, **When** updating, **Then** branches pull latest commits but tags remain fixed
5. **Given** 10+ plugins, **When** updating, **Then** operations complete in under 30 seconds with clear progress

---

### User Story 5 - Self-Update System (Priority: P3)

A user wants to keep Pulsar itself updated to benefit from bug fixes and new features without manual git operations.

**Why this priority**: Ensures users benefit from improvements and maintains project momentum through automated updates.

**Independent Test**: User checks for updates, is notified of new version, and can update pulsar itself with a single command.

**Acceptance Scenarios**:

1. **Given** a new pulsar version available, **When** starting a new shell, **Then** user sees a non-intrusive update notification
2. **Given** update notification, **When** user runs `pulsar-self-update`, **Then** pulsar updates to latest stable version
3. **Given** user wants edge versions, **When** setting `PULSAR_UPDATE_CHANNEL=edge`, **Then** updates pull from main branch instead of tags
4. **Given** user wants no notifications, **When** setting `PULSAR_UPDATE_CHANNEL=off`, **Then** no update checks or notifications occur
5. **Given** pulsar update completes, **When** sourcing pulsar again, **Then** new version is active immediately

---

### User Story 6 - Performance Optimization (Priority: P3)

A user wants fast shell startup times despite having many plugins. They want optional compilation and efficient caching.

**Why this priority**: Performance directly impacts daily developer experience; slow shells are abandoned.

**Independent Test**: User measures shell startup time with 10+ plugins and observes sub-100ms overhead from pulsar itself.

**Acceptance Scenarios**:

1. **Given** 10 plugins configured, **When** starting a new shell, **Then** pulsar overhead (excluding plugin sourcing) is under 50ms
2. **Given** user enables `PULSAR_AUTOCOMPILE=true`, **When** plugins load, **Then** .zwc bytecode files are created for faster subsequent loads
3. **Given** compiled plugins, **When** starting subsequent shells, **Then** load times are noticeably faster
4. **Given** parallel cloning operations, **When** first-time setup with 10 plugins, **Then** all clones complete in under 10 seconds
5. **Given** 100+ plugins configured, **When** loading, **Then** system remains responsive and operations complete without timeout

---

### User Story 7 - Prezto Support (Priority: P4)

A Prezto user wants to use Prezto modules alongside regular plugins with proper shorthand syntax and module structure handling.

**Why this priority**: Expands user base to include Prezto community; relatively small additional effort given OMZ work.

**Independent Test**: User declares Prezto modules using shorthand, and modules load with proper structure handling.

**Acceptance Scenarios**:

1. **Given** a Prezto module name, **When** user declares `PREZ::git`, **Then** sorin-ionescu/prezto repo is cloned and modules/git is loaded
2. **Given** Prezto modules, **When** loading, **Then** init.zsh files within module directories are properly discovered and sourced
3. **Given** mixed Prezto and regular plugins, **When** loading all, **Then** both types coexist without conflicts

---

### Edge Cases

- What happens when a plugin repository is renamed or deleted upstream?
- How does the system handle when user's disk is full during clone operation?
- What happens when git executable is not available on PATH?
- How does the system behave when network is completely unavailable?
- What happens when a plugin has no recognizable entry point files?
- How does the system handle circular dependencies if plugins load each other?
- What happens when XDG_CACHE_HOME is set to a read-only location?
- How does the system handle when a user has no write permissions to cache directory?
- What happens when plugin repository uses non-standard branch names (not main/master)?
- How does the system handle plugins with very large repository sizes (>1GB)?
- What happens when user forces re-clone while plugin is actively being used?
- How does the system behave in non-interactive shells (scripts, CI/CD)?

## Requirements *(mandatory)*

### Functional Requirements

#### Core Plugin Management

- **FR-001**: System MUST support declarative plugin configuration via Zsh arrays
- **FR-002**: System MUST automatically clone plugins from Git repositories on first use
- **FR-003**: System MUST cache cloned plugins in XDG_CACHE_HOME/pulsar directory
- **FR-004**: System MUST detect and use existing cached plugins without re-cloning
- **FR-005**: System MUST automatically discover plugin entry points using 5-step precedence (plugin.zsh, init.zsh, \*.plugin.zsh, \*.zsh, first .zsh alphabetically)
- **FR-006**: System MUST support parallel plugin cloning with bounded concurrency (CPU core count)
- **FR-007**: System MUST load plugins in the order they are declared in the configuration array
- **FR-008**: System MUST provide manual function calls for users who prefer imperative control (plugin-clone, plugin-load, plugin-update)
- **FR-009**: System MUST support local plugin paths (file:// or absolute paths) without requiring git

#### Version Control

- **FR-010**: System MUST support version pinning using `repo@ref` syntax where ref can be tag, branch, or commit SHA
- **FR-011**: System MUST checkout specified ref after cloning when version pinning is used
- **FR-012**: System MUST respect pinned versions during updates (tags stay fixed, branches pull latest)
- **FR-013**: System MUST provide option to force re-clone of plugins (PULSAR_FORCE_RECLONE)

#### Oh-My-Zsh Compatibility

- **FR-014**: System MUST support `OMZP::plugin` shorthand that expands to `ohmyzsh/ohmyzsh/plugins/plugin`
- **FR-015**: System MUST support `OMZL::lib` shorthand that expands to `ohmyzsh/ohmyzsh/lib/lib`
- **FR-016**: System MUST support `OMZT::theme` shorthand that expands to `ohmyzsh/ohmyzsh/themes/theme`
- **FR-017**: System MUST handle OMZ plugins (directories with .plugin.zsh files)
- **FR-018**: System MUST handle OMZ lib files (direct .zsh files, not directories)
- **FR-019**: System MUST handle OMZ themes (direct .zsh-theme files)
- **FR-020**: System MUST automatically initialize completion system (compinit) when loading OMZ plugins

#### Prezto Compatibility

- **FR-021**: System MUST support `PREZ::module` shorthand that expands to `sorin-ionescu/prezto/modules/module`
- **FR-022**: System MUST handle Prezto module structure (directories with init.zsh files)

#### Update System

- **FR-023**: System MUST support bulk plugin updates via `plugin-update` command
- **FR-024**: System MUST update plugins in parallel with progress indication
- **FR-025**: System MUST handle update failures gracefully (continue updating other plugins)
- **FR-026**: System MUST report which plugins were updated and which had errors

#### Self-Update

- **FR-027**: System MUST support self-update functionality via `pulsar-self-update` command
- **FR-028**: System MUST check for new versions against GitHub releases (stable channel) or main branch (edge channel)
- **FR-029**: System MUST display update notifications on shell startup when new version is available (configurable)
- **FR-030**: System MUST support three update channels: stable (default), edge, and off
- **FR-031**: System MUST respect `PULSAR_UPDATE_CHANNEL` environment variable for channel selection

#### Performance Optimization

- **FR-032**: System MUST support optional bytecode compilation via `PULSAR_AUTOCOMPILE` flag
- **FR-033**: System MUST compile plugins to .zwc files when autocompile is enabled
- **FR-034**: System MUST compile pulsar.zsh itself when autocompile is enabled
- **FR-035**: System MUST provide manual compilation via `plugin-compile` command
- **FR-036**: System MUST keep manager overhead (excluding plugin sourcing) under 50ms

#### Error Handling and User Experience

- **FR-037**: System MUST display clear, actionable error messages for common failures (network, permissions, missing git)
- **FR-038**: System MUST use colored output for better readability (with NO_COLOR support)
- **FR-039**: System MUST display progress indicators for long-running operations (cloning, updating)
- **FR-040**: System MUST continue loading other plugins when one plugin fails
- **FR-041**: System MUST provide warning messages for non-critical issues (missing recommended files)
- **FR-042**: System MUST report which plugin failed and provide context for debugging

#### Loading Modes

- **FR-043**: System MUST support source mode (default - sources plugin files)
- **FR-044**: System MUST support PATH mode (adds plugin/bin to PATH without sourcing)
- **FR-045**: System MUST support fpath mode (adds plugin directory to fpath for completions)
- **FR-046**: System MUST allow `path:` prefix for PATH mode and `fpath:` prefix for fpath mode

#### Installation and Bootstrap

- **FR-047**: System MUST provide safe installation script with timestamped backups of .zshrc
- **FR-048**: System MUST respect ZDOTDIR for .zshrc location
- **FR-049**: System MUST support VS Code terminal integration via optional shim
- **FR-050**: System MUST create bootstrap file for VS Code when needed

#### Diagnostic Tools

- **FR-051**: System MUST provide `pulsar-doctor` command for environment validation
- **FR-052**: System MUST provide `pulsar-benchmark` command for performance measurement
- **FR-053**: System MUST report pulsar version via `PULSAR_VERSION` variable

### Key Entities

- **Plugin**: A Git repository containing Zsh code to be loaded into the shell environment
  - Attributes: Repository URL, local cache path, entry point file, loading mode, version ref
  - Can be regular plugin, OMZ plugin/lib/theme, or Prezto module

- **Plugin Entry Point**: The file within a plugin repository that should be sourced to initialize the plugin
  - Precedence order: plugin.zsh, init.zsh, \*.plugin.zsh, \*.zsh (first alphabetically)

- **Cache Directory**: XDG-compliant location where cloned plugins are stored
  - Default: $XDG_CACHE_HOME/pulsar or ~/.cache/pulsar
  - Structure: repos/user/repo subdirectories

- **Update Channel**: Configuration determining source for pulsar self-updates
  - Values: stable (GitHub releases), edge (main branch), off (disabled)

- **Loading Mode**: How a plugin is integrated into the shell
  - Values: source (default), PATH, fpath

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can install and configure basic plugin management in under 5 minutes from first discovery
- **SC-002**: Plugin manager overhead stays under 50ms (excluding actual plugin sourcing time)
- **SC-003**: 10 plugins clone concurrently in under 10 seconds on typical network
- **SC-004**: System successfully loads 100+ plugins without timeout or resource exhaustion
- **SC-005**: Bulk update of 20 plugins completes in under 30 seconds
- **SC-006**: 95% of plugins load successfully without requiring manual entry point specification
- **SC-007**: Oh-My-Zsh users can migrate their entire plugin configuration in under 10 minutes
- **SC-008**: Shell startup time remains under 2 seconds with 20 plugins loaded
- **SC-009**: Users can copy-paste example configurations and have them work without modification
- **SC-010**: Parallel operations achieve at least 3x speedup compared to sequential cloning
- **SC-011**: Installation script completes without errors on fresh systems with only Zsh and Git installed
- **SC-012**: System provides unambiguous error messages for 95% of common failure scenarios
- **SC-013**: Users can uninstall completely in 3 steps (remove .zshrc lines, delete cache, delete pulsar.zsh)
- **SC-014**: Update notifications appear within 24 hours of new release when using stable channel
- **SC-015**: Compiled plugins show measurable load time improvement (at least 20% faster)
