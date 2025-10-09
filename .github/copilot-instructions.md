# Pulsar Development Guidelines

Auto-generated context for GitHub Copilot. **Last updated**: 2025-10-08

## Project Overview

**Pulsar** is a minimal Zsh plugin manager following the KISS (Keep It Simple, Stupid) principle. Pure Zsh implementation with no external runtime dependencies.

## Active Technologies

- **Language**: Zsh 5.8+
- **Testing**: Native Zsh test framework (clitest-style)
- **Linting**: ShellCheck
- **Dependencies**: git (required), curl (optional), python3 (optional)
- **Current Version**: 0.6.0 (pre-1.0 development)

## Project Structure

```
pulsar/
├── pulsar.zsh              # Core implementation (~800 LOC)
├── install.sh              # Safe installer with backups
├── Makefile                # Build automation (lint, test, install-dev)
├── CHANGELOG.md            # Version history (SemVer compliant)
├── README.md               # User documentation
├── examples/               # Configuration examples
│   ├── pulsar_example.zsh
│   ├── pulsar_declarative.zsh
│   └── omz_prezto_example.zsh
├── tests/                  # Integration test suite (89 tests)
│   ├── test-pulsar.md
│   ├── test-updater.md
│   ├── test-omz-plugins.md
│   └── ...
├── docs/                   # Extended documentation
│   └── OMZ-PREZTO-GUIDE.md
├── specs/                  # Feature specifications (SpecKit)
│   └── 001-we-are-creating/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       └── ...
└── .specify/               # SpecKit framework
    ├── memory/
    │   └── constitution.md  # Project governance (v1.2.0)
    └── templates/
```

## Commands

```bash
# Testing
make test                    # Run full test suite (89 tests)
./tests/run-clitests        # Direct test execution

# Linting
make lint                    # Run ShellCheck on all shell files

# Development
make install-dev            # Install for development
make clean                  # Clean compiled files

# Benchmarking
zsh -c 'source pulsar.zsh && pulsar-benchmark'
```

## Code Style

### Zsh Conventions
- Follow idiomatic Zsh patterns (parameter expansion, arrays, etc.)
- ShellCheck compliant (SC2034, SC2154 disabled where needed)
- Use `local` for function-scoped variables
- Prefer `${var}` over `$var` for clarity
- Use `[[ ]]` for conditionals (not `[ ]`)

### Naming
- Functions: `kebab-case` (e.g., `plugin-clone`, `pulsar-self-update`)
- Variables: `UPPER_SNAKE_CASE` for globals (e.g., `PULSAR_PLUGINS`)
- Variables: `lower_snake_case` for locals
- Private functions: prefix with underscore (e.g., `_internal_helper`)

### Error Handling
- Use `warn` and `error` functions for user messages
- Graceful degradation (warn and continue when possible)
- Exit codes: 0=success, 1=error, 2=usage error

### Performance
- Target: <50ms manager overhead
- Use parallel operations for cloning/updates (bounded by CPU cores)
- Cache plugin paths in XDG_CACHE_HOME
- Optional bytecode compilation via zcompile

## Constitutional Principles (v1.2.0)

All development MUST comply with `.specify/memory/constitution.md`:

1. **Branch-Based Workflow** - ALL work in feature branches, NO direct commits to main
2. **Code Quality Standards** - ShellCheck clean, meaningful names, <10 cyclomatic complexity
3. **Testing Standards** - 80% coverage for critical paths, all tests pass before merge
4. **User Experience Consistency** - Clear error messages, consistent output, progress indicators
5. **Performance Requirements** - Documented benchmarks, <100ms interactive commands
6. **Specification Discipline** - Only canonical docs in specs/ (no status reports)
7. **Semantic Versioning** - Strict SemVer adherence, CHANGELOG.md required

## Recent Changes

- **v0.6.0 (2025-10-08)**: Added Oh-My-Zsh shorthand aliases (OMZP::, OMZL::, OMZT::), automatic completion initialization, enhanced error messages, comprehensive OMZ/Prezto documentation
- **v0.5.0 (2025-10-08)**: Core implementation - parallel plugin management, automatic init discovery, multiple loading modes, version pinning, self-update system, compilation support, VS Code integration
- **Constitution v1.2.0 (2025-10-08)**: Added Principle VII (Semantic Versioning) to prevent version inflation
- **Constitution v1.1.0 (2025-10-08)**: Added Principle VI (Specification Discipline) to keep specs/ directory clean

## Development Workflow

### Starting New Work
```bash
git checkout main && git pull
git checkout -b 002-feature-name
# Make changes
git add -A && git commit -m "feat: description"
git push origin 002-feature-name
# Open PR to main
```

### Before Committing
```bash
make lint          # Must pass ShellCheck
make test          # Must pass all 89 tests
```

### Commit Format
Follow Conventional Commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements

## Key Features

- **Declarative Configuration**: Array-based plugin lists
- **Parallel Operations**: Concurrent cloning and updates
- **Version Pinning**: Support for tags, branches, commits (`repo@ref`)
- **Auto-discovery**: 5-step precedence for plugin entry points
- **OMZ/Prezto Support**: Shorthand aliases and proper file structure handling
- **Self-Update**: Stable/edge channels with automatic notifications
- **XDG Compliance**: Respects XDG Base Directory spec
- **Minimal Dependencies**: Pure Zsh + git only

## Important Notes

- Pre-1.0.0 version: Breaking changes may occur in MINOR versions
- v1.0.0 reserved for production-ready signal
- Process documentation goes in docs/ or .github/, NOT specs/
- CHANGELOG.md must document all releases per SemVer categories
- Git tags required for all releases (format: `vMAJOR.MINOR.PATCH`)

<!-- MANUAL ADDITIONS START -->
<!-- Add any project-specific guidance here that should persist across updates -->
<!-- MANUAL ADDITIONS END -->
