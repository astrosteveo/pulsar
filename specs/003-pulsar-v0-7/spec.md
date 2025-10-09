# Feature Specification: Pulsar v0.7.0 - Silent & Clean

**Feature Branch**: `003-pulsar-v0-7`
**Created**: 2025-10-08
**Status**: Draft
**Input**: User description: "Pulsar v0.7.0: Silent by default with PULSAR_VERBOSE opt-in flag. Remove legacy PULSAR_PATH/PULSAR_FPATH arrays (breaking change). Remove VS Code shim. Simplify codebase to ~700-800 LOC while keeping core features: parallel operations, OMZ/Prezto shortcuts, version pinning, self-update, three loading modes (source/path/fpath with prefix syntax). Default experience should be clean and silent - only show output during actual operations (cloning, updating, errors). Global verbosity flag for debugging. Modern, fast, KISS philosophy."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Silent Shell Startup (Priority: P1)

A user wants their shell to start instantly and silently when plugins are already cached. They should only see output when something actually happens (first-time clone, update, error).

**Why this priority**: Core value proposition - clean, fast startup experience is the primary user-facing improvement in v0.7.0. This is what users will notice immediately.

**Independent Test**: User opens a new shell with 10 cached plugins and sees no output. Startup time is indistinguishable from v0.6.0 but with zero visual noise.

**Acceptance Scenarios**:

1. **Given** plugins are already cached, **When** user starts a new shell, **Then** no output is displayed and plugins load silently
2. **Given** a plugin needs to be cloned for the first time, **When** user starts a shell, **Then** only cloning progress is shown with a concise message
3. **Given** all plugins are current, **When** user runs `plugin-update`, **Then** output shows "✓ All plugins up to date" and nothing else
4. **Given** plugins have updates available, **When** user runs `plugin-update`, **Then** output shows only which plugins updated with commit counts
5. **Given** an error occurs during plugin loading, **When** shell starts, **Then** error is displayed clearly while other plugins continue loading silently

---

### User Story 2 - Simplified Plugin Configuration (Priority: P1)

A user wants a single, clean array for all plugins using intuitive prefix syntax for loading modes. No separate arrays, no confusion about where to put what.

**Why this priority**: Breaking change that must work perfectly. Simplification is the core architectural improvement that enables future maintainability.

**Independent Test**: User migrates from v0.6.0 configuration with separate PULSAR_PATH/PULSAR_FPATH arrays to v0.7.0 unified PULSAR_PLUGINS array. All plugins work identically.

**Acceptance Scenarios**:

1. **Given** user has basic plugins, **When** they declare `PULSAR_PLUGINS=(user/repo1 user/repo2)`, **Then** both plugins source normally (default mode)
2. **Given** user needs PATH mode, **When** they declare `PULSAR_PLUGINS=(path:user/repo)`, **Then** repo's bin/ directory is added to PATH without sourcing
3. **Given** user needs fpath mode, **When** they declare `PULSAR_PLUGINS=(fpath:user/repo)`, **Then** repo directory is added to fpath for completions without sourcing
4. **Given** user mixes modes, **When** they declare `PULSAR_PLUGINS=(user/repo1 fpath:user/repo2 path:user/repo3)`, **Then** each plugin loads with its specified mode
5. **Given** user has v0.6.0 config with PULSAR_PATH/PULSAR_FPATH, **When** they upgrade, **Then** system shows clear deprecation warning with migration example

---

### User Story 3 - Minimal Zshrc Experience (Priority: P2)

A new user wants the simplest possible .zshrc configuration that "just works" with sensible defaults. Like Oh-My-Zsh's 4-line setup, but for Pulsar.

**Why this priority**: First impression matters. Lower barrier to entry means more adoption. Users can start minimal and add complexity later.

**Independent Test**: User runs installer, chooses minimal setup, and ends up with a 5-10 line .zshrc that provides excellent defaults: completions, key bindings, and a clean prompt.

**Acceptance Scenarios**:

1. **Given** fresh Zsh install, **When** user runs install.sh, **Then** installer asks "Install with sensible defaults? (completions, keybinds, prompt) [Y/n]"
2. **Given** user chooses default setup, **When** installer completes, **Then** .zshrc contains minimal config (~5-10 lines) that sources Pulsar and optional defaults
3. **Given** minimal setup chosen, **When** new shell starts, **Then** user has working completions, useful key bindings (Ctrl+R, arrow keys), and a clean prompt
4. **Given** user chooses custom setup, **When** installer completes, **Then** .zshrc contains only Pulsar source line (bare minimum for advanced users)
5. **Given** minimal setup, **When** user wants to customize, **Then** clear comments in .zshrc explain what each default does and how to disable

---

### User Story 4 - Debug Mode for Troubleshooting (Priority: P2)

A user encounters an issue and needs to see what Pulsar is doing. They set a global verbose flag and get detailed output for debugging.

**Why this priority**: Essential for maintainability and user support. Users need a way to troubleshoot without diving into code.

**Independent Test**: User sets `PULSAR_VERBOSE=1` in their config, restarts shell, and sees detailed output showing what Pulsar is doing for each plugin.

**Acceptance Scenarios**:

1. **Given** `PULSAR_VERBOSE=1` is set, **When** user starts shell, **Then** output shows each plugin being processed with timing information
2. **Given** verbose mode is off (default), **When** user starts shell with cached plugins, **Then** absolutely no output appears
3. **Given** `PULSAR_VERBOSE=1`, **When** plugin is cloned, **Then** output shows git clone command and progress details
4. **Given** `PULSAR_VERBOSE=1`, **When** entry point is discovered, **Then** output shows which files were checked and which was selected
5. **Given** user unsets PULSAR_VERBOSE, **When** shell starts, **Then** system returns to silent mode immediately

---

### User Story 5 - Streamlined Codebase (Priority: P3)

A developer wants to understand and maintain Pulsar's codebase easily. The code should be clean, well-documented, and under 800 lines without sacrificing core functionality.

**Why this priority**: Long-term maintainability and contribution-friendliness. Simpler code means fewer bugs and easier improvements.

**Independent Test**: Developer reads through pulsar.zsh and understands the flow within 30 minutes. Line count is verifiably under 800 lines.

**Acceptance Scenarios**:

1. **Given** v0.6.0 codebase (~1089 lines), **When** v0.7.0 is complete, **Then** pulsar.zsh is 700-800 lines while retaining all core features
2. **Given** legacy PULSAR_PATH/PULSAR_FPATH code, **When** removed, **Then** prefix parsing in unified array handles all modes cleanly
3. **Given** VS Code shim code, **When** removed, **Then** codebase is simpler without affecting core plugin management
4. **Given** compilation complexity, **When** simplified or removed, **Then** codebase is cleaner without performance regression
5. **Given** entry point discovery (5 steps), **When** optimized, **Then** discovery still works for 95%+ of plugins with fewer code paths

---

### User Story 6 - Preserved Core Features (Priority: P1)

A user upgrades from v0.6.0 to v0.7.0 and expects all essential functionality to work identically: parallel cloning, OMZ/Prezto shortcuts, version pinning, self-update, and fast performance.

**Why this priority**: Critical for user retention. Breaking changes are acceptable, but feature regression is not. This defines what MUST work.

**Independent Test**: User runs v0.6.0 test suite against v0.7.0 codebase. All core feature tests pass (excluding tests for removed features).

**Acceptance Scenarios**:

1. **Given** user has 10 plugins, **When** first-time cloning, **Then** all plugins clone in parallel completing in under 10 seconds
2. **Given** user uses `OMZP::git`, **When** loading plugins, **Then** Oh-My-Zsh git plugin loads correctly with shorthand expansion
3. **Given** user pins a plugin with `user/repo@v1.0`, **When** updating, **Then** plugin stays at v1.0 tag and doesn't update
4. **Given** new Pulsar version available, **When** user runs `pulsar-self-update`, **Then** Pulsar updates to latest stable release
5. **Given** 20 plugins configured, **When** shell starts, **Then** Pulsar overhead remains under 50ms (excluding plugin sourcing time)

---

### Edge Cases

- What happens when user has both new unified array and old separate arrays in config?
- How does system handle invalid prefix syntax (e.g., `invalidmode:user/repo`)?
- What happens when user sets `PULSAR_VERBOSE` to non-boolean values (e.g., `PULSAR_VERBOSE=yes`)?
- How does deprecation warning display if user has no TTY (non-interactive shell)?
- What happens when a plugin has both source and path needs (e.g., needs bin/ in PATH AND needs sourcing)?
- How does system behave when user upgrades from v0.6.0 with edge channel configured?
- What happens when `PULSAR_VERBOSE` is changed mid-session (e.g., exported in current shell)?
- How does system handle when user has manually compiled .zwc files that reference removed code?
- What happens if user has custom wrapper functions around old PULSAR_PATH/PULSAR_FPATH?
- How does installer handle when .zshrc already exists but doesn't source Pulsar?
- How does example configs prompt handle non-interactive installation (e.g., CI/CD, scripted installs)?
- What happens when user wants to upgrade from v0.6.0 but already has custom history/completion/prompt config?
- What happens if user uncomments prompt example but their terminal doesn't support color codes?

## Requirements *(mandatory)*

### Functional Requirements

#### Silent Operation

- **FR-001**: System MUST produce zero output during normal shell startup when all plugins are cached and current
- **FR-002**: System MUST only display output when performing actual operations: cloning, updating, compiling, or encountering errors
- **FR-003**: System MUST show concise progress messages during long-running operations (cloning 10+ plugins, bulk updates)
- **FR-004**: System MUST display clear, actionable error messages when operations fail
- **FR-005**: System MUST respect NO_COLOR environment variable for colorless output

#### Verbose Mode

- **FR-006**: System MUST support `PULSAR_VERBOSE=1` environment variable for debug output
- **FR-007**: When PULSAR_VERBOSE is enabled, system MUST show detailed operation logs including: plugin processing order, entry point discovery steps, timing information, git commands executed
- **FR-008**: Verbose mode MUST be toggleable without restarting shell (applies to subsequent operations)
- **FR-009**: System MUST treat any truthy value for PULSAR_VERBOSE as enabled: 1, true, yes, on (case-insensitive)
- **FR-010**: System MUST default to silent mode when PULSAR_VERBOSE is unset or empty

#### Unified Configuration

- **FR-011**: System MUST support single PULSAR_PLUGINS array for all plugin configurations
- **FR-012**: System MUST support prefix syntax for loading modes: `mode:repo` where mode is `path`, `fpath`, or omitted (default source)
- **FR-013**: System MUST parse `path:user/repo` to add repo's bin/ subdirectory to PATH without sourcing
- **FR-014**: System MUST parse `fpath:user/repo` to add repo directory to fpath without sourcing
- **FR-015**: System MUST parse `user/repo` (no prefix) to source plugin using entry point discovery (default mode)
- **FR-016**: System MUST support mixing all three modes in single PULSAR_PLUGINS array
- **FR-017**: System MUST support combining mode prefix with version pinning: `mode:user/repo@ref`
- **FR-018**: System MUST support combining mode prefix with OMZ/Prezto shortcuts: `fpath:OMZP::git`

#### Minimal Zshrc Experience

- **FR-019**: Installer MUST prompt user: "Include example configs? (OMZ libs, custom setup) [Y/n]"
- **FR-020**: When user selects yes (Y), installer MUST generate .zshrc with Pulsar source + commented OMZ library suggestions
- **FR-021**: Generated .zshrc MUST be 30-50 lines total including Pulsar config and commented OMZ lib examples
- **FR-022**: Example configuration MUST show how to load OMZ libraries (OMZL::history, OMZL::key-bindings, OMZL::completion, OMZL::theme-and-appearance) as commented entries in PULSAR_PLUGINS array
- **FR-023**: Template MUST include popular OMZ lib choices with brief description of what each provides (e.g., "OMZL::key-bindings # Comprehensive key bindings (arrows, Ctrl+R, etc.)")
- **FR-024**: Template MUST include link to full OMZ lib list: <https://github.com/ohmyzsh/ohmyzsh/tree/master/lib>
- **FR-025**: Template MUST provide simple custom alternative (basic completion, history, key bindings, prompt) for users who prefer not using OMZ libs
- **FR-026**: All example configs MUST be commented out by default (user uncomments what they want)
- **FR-027**: When user selects no (n), installer MUST generate minimal .zshrc with only Pulsar source and plugin array
- **FR-028**: Installer MUST create timestamped backup of existing .zshrc before modifications
- **FR-029**: Generated .zshrc MUST work immediately without requiring user edits (sensible plugin examples included)

#### Legacy Deprecation

- **FR-029**: System MUST remove support for separate PULSAR_PATH and PULSAR_FPATH arrays
- **FR-030**: System MUST detect presence of PULSAR_PATH or PULSAR_FPATH in user config
- **FR-031**: When legacy arrays detected, system MUST display one-time migration warning with example
- **FR-032**: Migration warning MUST show exact replacement syntax for user's config
- **FR-033**: System MUST NOT process legacy arrays (require explicit migration)
- **FR-034**: System MUST remove VS Code shim support and related installation code

#### Code Simplification

- **FR-035**: Total line count of pulsar.zsh MUST be between 700-800 lines
- **FR-036**: System MUST remove all VS Code integration code (shim installation, bootstrap)
- **FR-037**: System MUST simplify or remove compilation support code (decision to be made during implementation)
- **FR-038**: System MUST optimize entry point discovery to fewer steps while maintaining 95%+ success rate
- **FR-039**: All removed features MUST be documented in CHANGELOG with clear migration notes

#### Preserved Core Features

- **FR-040**: System MUST maintain parallel cloning with same performance characteristics (3x+ speedup)
- **FR-041**: System MUST maintain all Oh-My-Zsh shortcuts: OMZP::, OMZL::, OMZT::
- **FR-042**: System MUST maintain Prezto shortcut: PREZ::
- **FR-043**: System MUST maintain version pinning syntax: `repo@ref` for tags, branches, commits
- **FR-044**: System MUST maintain self-update system with stable/edge/off channels
- **FR-045**: System MUST maintain plugin-update command with bulk parallel updates
- **FR-046**: System MUST maintain plugin-clone, plugin-load, plugin-update manual functions
- **FR-047**: System MUST maintain automatic entry point discovery with same precedence rules
- **FR-048**: System MUST maintain XDG Base Directory compliance for cache location
- **FR-049**: System MUST maintain manager overhead under 50ms (excluding plugin sourcing)
- **FR-050**: System MUST maintain support for 100+ plugins without performance degradation

#### User Experience

- **FR-051**: System MUST display startup banner only when operations are performed (not on silent cached loads)
- **FR-052**: Error messages MUST include plugin name, operation attempted, and suggested fix
- **FR-053**: Update notifications MUST remain non-intrusive (single line, suppressible)
- **FR-054**: System MUST maintain colored output for readability (when NO_COLOR not set)
- **FR-055**: System MUST provide pulsar-doctor command for environment validation

### Key Entities

- **Plugin Specification**: A string defining how to load a plugin
  - Format: `[mode:]repo[@ref]`
  - Attributes: loading mode (source/path/fpath), repository identifier, optional version reference
  - Example: `path:romkatv/zsh-bench@main`

- **Loading Mode**: How a plugin is integrated into the shell
  - Values: source (default), path (bin/ to PATH), fpath (completions)
  - Behavior: Determines what Pulsar does with the plugin directory

- **Verbose Flag**: Global debug toggle
  - Values: unset/empty (silent), 1/true/yes/on (verbose)
  - Scope: Environment variable checked at operation time

- **Legacy Array**: Deprecated configuration pattern
  - Types: PULSAR_PATH, PULSAR_FPATH
  - Status: Removed in v0.7.0, detection triggers migration warning

- **Migration Warning**: One-time message guiding users to new syntax
  - Trigger: Detection of PULSAR_PATH or PULSAR_FPATH in environment
  - Content: Clear before/after example showing unified array syntax

- **Example Configurations**: Commented OMZ library suggestions in generated .zshrc
  - Type: OMZL:: entries in PULSAR_PLUGINS array (leverages existing OMZ libs)
  - Content: Suggestions for history, key-bindings, completion, theme-and-appearance
  - Alternative: Simple custom setup (basic completion/history/keybinds/prompt) for non-OMZ users
  - Opt-in: User uncomments desired OMZ libs or custom setup
  - Documentation: Inline comments explaining what each lib provides

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Shell startup with 20 cached plugins produces zero visible output and completes in under 2 seconds total
- **SC-002**: Pulsar manager overhead (excluding plugin sourcing) remains under 50ms in both silent and verbose modes
- **SC-003**: Codebase size is reduced from 1089 lines to 700-800 lines (30%+ reduction)
- **SC-004**: Users can migrate from v0.6.0 configuration to v0.7.0 in under 5 minutes with clear guidance
- **SC-005**: 95% of users never need to enable verbose mode (core operations work silently)
- **SC-006**: First-time setup with 10 plugins shows concise progress completing in under 10 seconds
- **SC-007**: Bulk update of 20 plugins shows only summary line: "✓ 18 current, 2 updated (3.2s)"
- **SC-008**: Verbose mode output enables developers to diagnose 90% of issues without reading source code
- **SC-009**: All 89 existing tests pass with modifications only to removed-feature tests
- **SC-010**: Breaking changes are clearly documented in CHANGELOG with before/after examples
- **SC-011**: Plugin loading modes work identically to v0.6.0 but with cleaner syntax
- **SC-012**: Self-update system continues to work without user intervention
- **SC-013**: OMZ/Prezto shortcuts expand correctly in all three loading modes
- **SC-014**: Version pinning respects pins during updates (tags stay fixed, branches pull latest)
- **SC-015**: Users can uninstall legacy config in 3 steps: remove old arrays, update to unified syntax, restart shell
- **SC-016**: New users complete installation with example configs in under 2 minutes from curl to working shell
- **SC-017**: Generated .zshrc with examples is 30-50 lines total (commented OMZ lib suggestions + simple custom alternative)
- **SC-018**: Generated .zshrc works immediately after install (sensible plugin examples, no user edits required)
