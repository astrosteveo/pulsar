# Implementation Plan: Minimal Zsh Plugin Manager (Pulsar)

**Branch**: `001-we-are-creating` | **Date**: 2025-10-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-we-are-creating/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a minimal, fast, KISS-principle Zsh plugin manager inspired by mattmc3/zsh_unplugged. Core capabilities: parallel plugin cloning from GitHub, automatic init file discovery, declarative and manual plugin loading modes, oh-my-zsh plugin compatibility via subdirectory paths (zinit-style), plugin updates and compilation, and self-update functionality. Technical approach: Pure Zsh + git implementation (no external runtimes), <1000 lines of code, XDG Base Directory compliance, graceful error handling with informative warnings, and sub-50ms startup overhead. Emphasizes ease of use, idiomatic Zsh patterns, well-designed conditionals for reliability, and simple customization through environment variables.

## Technical Context

**Language/Version**: Zsh 5.8+ (pure shell scripting, no external runtimes)
**Primary Dependencies**: git (required), curl (optional for installer/self-update)
**Storage**: File system only - XDG cache directory (`${XDG_CACHE_HOME:-$HOME/.cache}/pulsar`), user's `.zshrc`, bootstrap file in `$ZSH/lib/`
**Testing**: Zsh test framework (ztst) or custom test runner using Zsh's built-in testing capabilities
**Target Platform**: Linux, macOS, WSL (any Unix-like system with Zsh 5.8+)
**Project Type**: Single shell script library with installer
**Performance Goals**:

- Plugin manager overhead < 50ms on shell startup
- Parallel cloning 3x faster than serial (10+ plugins in < 10s)
- Plugin loading < 5 minutes for 100+ plugins
- Individual command execution < 100ms (interactive feel)

**Constraints**:

- Pure Zsh + git only (no Python, Ruby, Node.js)
- Codebase < 1000 lines of code (counted by `cloc pulsar.zsh --exclude-blank --exclude-comments` - KISS principle)
- No sudo/root required
- Must work identically with/without ZDOTDIR
- Backward compatible with existing Pulsar configs
- Graceful degradation when optional tools missing

**Scale/Scope**:

- Support 100+ plugins efficiently
- Handle monorepos with subdirectory plugins (OMZ-style)
- Typical user: 10-20 plugins
- Power user: 50-100 plugins

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Branch-Based Workflow Compliance

- [x] Feature branch created: `001-we-are-creating`
- [x] No commits directly to `main` branch
- [x] PR workflow documented and followed (will open PR after implementation)

### Code Quality Standards

- [x] Linting and formatting tools configured: ShellCheck for Zsh linting, EditorConfig for consistency
- [x] Code style guide identified: Google Shell Style Guide adapted for Zsh idioms
- [x] Complexity limits defined: Functions < 50 lines, cyclomatic complexity < 10, max nesting depth 4
- [x] Code review process established: PR review required before merge

### Shell Safety Requirements

- [x] **Quoting**: All variable expansions MUST be quoted (`"$var"`, `"${array[@]}"`) unless intentional word splitting required
- [x] **Error Propagation**: Functions MUST return 0 on success, non-zero on failure; critical errors propagated to caller (see FR-021)
- [x] **Array Handling**: Array expansions MUST use `"${array[@]}"` syntax to preserve elements with spaces
- [x] **Subshell Isolation**: Parallel operations MUST use subshells/background jobs with proper job control and cleanup
- [x] **Glob Pattern Safety**: Use `setopt nullglob` for safe glob iteration; validate glob results before processing
- [x] **PATH Safety**: When adding to PATH/fpath, check for duplicates to prevent PATH pollution
- [x] **Special Characters**: Handle special characters in paths/names using proper quoting and escaping
- [x] **Infinite Recursion Prevention**: Plugin loading tracks already-loaded plugins to prevent circular dependencies
- [x] **Directory Safety**: Validate and create directories with error checking (cache dirs, ZDOTDIR, etc.)
- [x] **Git Operation Safety**: Validate git availability, handle missing git gracefully, timeout long operations if possible

### Testing Standards

- [x] Test coverage targets defined: 80% for core functions (clone, load, update), 60% overall
- [x] Test types identified: integration tests (primary), contract tests for CLI interface, regression tests
- [x] Test execution time budgets set: individual tests < 1s, full suite < 5min
- [x] Acceptance tests mapped to user stories: Each user story has corresponding test scenarios in tests/

### User Experience Consistency

- [x] CLI interface follows standard conventions: Commands use stdin/args, output to stdout, errors to stderr
- [x] Error messages are user-friendly: "Plugin 'user/repo' failed to clone: repository not found" (not raw git output)
- [x] Output formats are consistent: All informational messages follow same pattern, color codes consistent
- [x] Progress indicators for long operations: Parallel cloning shows progress, update shows per-plugin status
- [x] Documentation includes usage examples: README with Quick Start, examples/ directory with full configs

### Performance Requirements

- [x] Performance benchmarks documented: Startup overhead < 50ms, parallel cloning benchmarks included
- [x] Response time targets defined: All interactive commands < 100ms, update/clone operations < 10s for typical load
- [x] Resource usage limits established: No persistent background processes, temp file cleanup, bounded memory
- [x] Performance testing strategy: Use zsh-bench for startup timing, custom benchmarks for clone/update
- [x] Scalability considerations documented: Parallel operations scale to CPU cores, tested with 100+ plugins

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
pulsar/                          # Repository root
├── pulsar.zsh                   # Main plugin manager script (<1000 lines)
├── install.sh                   # Installer script (backs up .zshrc, sets up bootstrap)
├── .editorconfig               # Editor consistency
├── .shellcheckrc               # ShellCheck configuration
├── LICENSE                      # Unlicense (public domain)
├── README.md                    # User-facing documentation
├── CHANGELOG.md                 # Version history (keep-a-changelog format)
├── Makefile                     # Build commands (test, lint, install-dev)
│
├── examples/                    # Example configurations
│   ├── pulsar_declarative.zsh  # Declarative array-based config
│   ├── pulsar_example.zsh      # Full-featured manual config
│   └── omz_migration.zsh       # Example OMZ plugin migration
│
├── tests/                       # Test suite
│   ├── __init__.zsh            # Test framework setup
│   ├── run-clitests            # Test runner script
│   ├── test-pulsar.md          # Core functionality tests (clone, load, update)
│   ├── test-omz-plugins.md     # OMZ subdirectory path tests
│   ├── test-error-handling.md  # Graceful failure tests
│   ├── test-installer.md       # Install script tests (backup, shim creation)
│   ├── test-conflicts.md       # Plugin conflict detection tests
│   └── test-performance.md     # Startup time and scalability benchmarks
│
└── assets/                      # Documentation assets
    └── README.md                # Asset documentation
```

**Structure Decision**: Single-file core implementation (pulsar.zsh) keeps the codebase minimal and easy to understand. The <1000 line constraint encourages tight, focused functions. Installer is separate to keep installation concerns isolated. Tests are organized by functional area, using Markdown-based test format for readability. Examples provide copy-paste starting points for common use cases. This structure supports the KISS principle while remaining feature-rich through well-designed conditionals and idiomatic Zsh patterns.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: ✅ No Constitution violations

This implementation fully complies with all 5 Constitution principles:

1. **Branch-Based Workflow**: Feature branch `001-we-are-creating` created, all work isolated from `main`
2. **Code Quality**: Single-file approach (<1000 LOC), ShellCheck linting, Google Shell Style adapted for Zsh
3. **Testing**: 80% critical path coverage target, integration tests for all user stories
4. **UX Consistency**: Clear error messages, progress indicators, consistent CLI patterns
5. **Performance**: Sub-50ms overhead target, parallel operations, benchmarking strategy defined

No complexity justifications needed. Design aligns with KISS principle while remaining feature-rich through idiomatic Zsh patterns and well-designed conditionals.
