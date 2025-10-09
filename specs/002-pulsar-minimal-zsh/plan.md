# Implementation Plan: Pulsar - Minimal Zsh Plugin Manager

**Branch**: `002-pulsar-minimal-zsh` | **Date**: 2025-10-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-pulsar-minimal-zsh/spec.md`

**Note**: This is a retrospective implementation plan documenting the technical architecture of Pulsar v0.6.0, which is already implemented and tested.

## Summary

Pulsar is a minimal Zsh plugin manager providing declarative plugin configuration with automatic cloning, parallel operations, version pinning, Oh-My-Zsh/Prezto compatibility, self-update capabilities, and performance optimization through bytecode compilation. The system follows the KISS principle with pure Zsh implementation (no external runtime dependencies) while supporting advanced features like shorthand aliases (OMZP::, OMZL::, OMZT::, PREZ::), multiple loading modes (source/PATH/fpath), and XDG Base Directory compliance.

## Technical Context

**Language/Version**: Zsh 5.8+ (pure shell script, no external runtime dependencies)
**Primary Dependencies**: git (required), curl (optional for release notes), python3 (optional for VS Code integration)
**Storage**: File system (XDG_CACHE_HOME for plugin cache, state files for update tracking)
**Testing**: Native Zsh test framework (clitest-style integration tests), 89 tests covering core functionality
**Target Platform**: Unix-like systems (Linux, macOS, BSD) with Zsh 5.8+
**Project Type**: Single project (shell script library with optional installer)
**Performance Goals**:

- Manager overhead < 50ms (excluding plugin sourcing)
- Parallel cloning: 10 plugins in < 10 seconds
- Shell startup with 20 plugins < 2 seconds total
- Parallel operations achieve 3x speedup vs sequential

**Constraints**:

- Pure Zsh implementation (no external interpreters)
- Minimal dependencies (only git required)
- XDG Base Directory compliance
- ShellCheck compliant code
- Interactive commands < 100ms response
- Non-interactive bulk operations < 30 seconds for 20 plugins

**Scale/Scope**:

- Target: 100+ plugins loaded efficiently
- Codebase: ~1100 LOC in single file (pulsar.zsh)
- Test suite: 89 integration tests
- User base: OMZ/Prezto migrators + new users

## Constitution Check

**GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.**

### Branch-Based Workflow Compliance

- [x] Feature branch created: `002-pulsar-minimal-zsh`
- [x] No commits directly to `main` branch (all work in feature branch)
- [x] PR workflow documented in constitution and Copilot instructions

### Code Quality Standards

- [x] Linting and formatting tools configured (ShellCheck via `make lint`)
- [x] Code style guide identified and documented (Zsh conventions, idiomatic patterns)
- [x] Complexity limits defined (functions follow single responsibility, cyclomatic complexity < 10)
- [x] Code review process established (PR-based, constitution compliance checked)

### Testing Standards

- [x] Test coverage targets defined (89 integration tests covering critical paths)
- [x] Test types identified (integration tests using clitest-style framework)
- [x] Test execution time budgets set (full suite runs in under 2 minutes)
- [x] Acceptance tests mapped to user stories (test files cover all major features)

### User Experience Consistency

- [x] CLI interface follows standard conventions (functions, environment variables, proper output)
- [x] Error messages are user-friendly and actionable (clear warnings, colored output)
- [x] Output formats are consistent (progress indicators, colored messages)
- [x] Progress indicators for long operations (cloning, updating with parallel progress)
- [x] Documentation includes usage examples (README.md, examples/ directory)

### Performance Requirements

- [x] Performance benchmarks documented for critical operations (`pulsar-benchmark` command)
- [x] Response time targets defined (manager overhead < 50ms, bulk ops < 30s)
- [x] Resource usage limits established (bounded parallelism by CPU cores)
- [x] Performance testing strategy defined (benchmark command, startup measurement)
- [x] Scalability considerations documented (tested with 100+ plugins)

### Specification Discipline

- [x] Only canonical spec documents in specs/ directory (spec.md, plan.md created; tasks.md, data-model.md, research.md, quickstart.md to be created)
- [x] No completion reports or status summaries planned for specs/
- [x] Implementation tracking via tasks.md checkboxes only (to be created in next phase)
- [x] Process documentation in docs/ or .github/ (OMZ-PREZTO-GUIDE.md in docs/, copilot-instructions.md in .github/)

### Semantic Versioning

- [x] Version numbering follows MAJOR.MINOR.PATCH format (currently v0.6.0)
- [x] Pre-1.0.0 status acknowledged (development phase, breaking changes allowed in MINOR)
- [x] Version 1.0.0 criteria defined for production readiness (reserved for stability signal)
- [x] CHANGELOG.md structure follows SemVer categories (Added, Changed, Fixed, etc.)
- [x] Git tag strategy documented for releases (vMAJOR.MINOR.PATCH format)

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
pulsar/
├── pulsar.zsh              # Main implementation (~1100 LOC)
├── install.sh              # Safe installer with backups
├── Makefile                # Build automation
├── CHANGELOG.md            # Version history (SemVer)
├── README.md               # User documentation
├── LICENSE                 # Unlicense
├── SPECKIT-WORKFLOW.md     # SpecKit usage guide
├── .github/
│   ├── copilot-instructions.md
│   └── prompts/            # SpecKit command prompts
├── examples/
│   ├── pulsar_example.zsh
│   ├── pulsar_declarative.zsh
│   └── omz_prezto_example.zsh
├── tests/
│   ├── run-clitests        # Test runner
│   ├── __init__.zsh        # Test framework
│   ├── test-pulsar.md      # Core functionality tests
│   ├── test-updater.md     # Self-update tests
│   ├── test-omz-plugins.md # OMZ compatibility tests
│   ├── test-advanced-zshrc.md
│   ├── test-deprecate-edge.md
│   ├── test-install-vscode-shim.md
│   └── test-ordered-list.md
├── docs/
│   └── OMZ-PREZTO-GUIDE.md # Migration documentation
├── assets/
│   ├── pulsar-demo.cast
│   └── README.md
├── specs/
│   ├── 001-we-are-creating/    # Original basic spec
│   └── 002-pulsar-minimal-zsh/ # Current comprehensive spec
└── .specify/
    ├── memory/
    │   └── constitution.md      # Project governance
    ├── templates/               # SpecKit templates
    └── scripts/                 # SpecKit automation
```

**Structure Decision**: Single project structure (shell script library). All functionality is in `pulsar.zsh` (~1100 LOC), with integration tests in `tests/`, usage examples in `examples/`, and documentation in root and `docs/`. This follows the KISS principle with minimal file structure overhead. The SpecKit framework lives in `.specify/` for development workflow support.

## Complexity Tracking

### Justification Required

No constitution violations. All checks passed.
