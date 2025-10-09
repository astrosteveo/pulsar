# Quick Start Guide

**Feature**: 002-pulsar-minimal-zsh
**Date**: 2025-10-08
**Audience**: Developers working on Pulsar

## Overview

This guide helps developers quickly set up their development environment for working on Pulsar, a minimal Zsh plugin manager. It covers installation, testing, making changes, and following the project's constitutional principles.

## Prerequisites

### Required

- **Zsh**: Version 5.8 or higher

  ```zsh
  zsh --version  # Should show >= 5.8
  ```

- **Git**: For cloning and version control

  ```zsh
  git --version  # Any reasonably modern version
  ```

### Optional

- **ShellCheck**: For linting

  ```zsh
  shellcheck --version  # For make lint
  ```

- **Python 3**: For VS Code integration scripts (optional)

## Quick Setup (5 minutes)

### 1. Clone the Repository

```zsh
git clone https://github.com/astrosteveo/pulsar.git
cd pulsar
```

### 2. Understand the Structure

```zsh
ls -la
# Key files:
# - pulsar.zsh      - Main implementation (~1100 LOC)
# - install.sh      - User installer
# - Makefile        - Development tasks
# - tests/          - 89 integration tests
# - examples/       - Usage examples
# - specs/          - SpecKit documentation
```

### 3. Run Tests

```zsh
make test
# All 89 tests should pass
# Takes ~1-2 minutes
```

### 4. Try Pulsar Locally

```zsh
# Source directly (doesn't modify your .zshrc)
source ./pulsar.zsh

# Test with example plugins
typeset -ga PULSAR_PLUGINS=(
  zsh-users/zsh-autosuggestions
)
plugin-load $PULSAR_PLUGINS

# Check it loaded
which _zsh_autosuggest_bind_widget  # Should show function
```

## Development Workflow

### Constitutional Principles (MUST READ)

Read `.specify/memory/constitution.md` - it contains 7 NON-NEGOTIABLE principles:

1. **Branch-Based Workflow** - ALL work in feature branches
2. **Code Quality Standards** - ShellCheck clean, readable code
3. **Testing Standards** - 89 tests must pass
4. **User Experience Consistency** - Clear errors, consistent output
5. **Performance Requirements** - <50ms overhead, <100ms interactive
6. **Specification Discipline** - Only canonical docs in specs/
7. **Semantic Versioning** - Pre-1.0.0 development, CHANGELOG required

### Branch-Based Workflow

```zsh
# 1. Start from main
git checkout main
git pull

# 2. Create feature branch
git checkout -b 003-your-feature-name

# 3. Make changes
# ... edit pulsar.zsh, add tests, update docs ...

# 4. Test your changes
make lint          # ShellCheck must pass
make test          # All tests must pass

# 5. Commit
git add -A
git commit -m "feat: add your feature description"

# 6. Push and PR
git push origin 003-your-feature-name
# Open PR on GitHub
```

### Running Tests

```zsh
# Run all tests
make test

# Run specific test file
make unit  # Runs test-pulsar.md only

# Run specific test directly
./tests/run-clitests tests/test-updater.md
```

### Linting

```zsh
# Run ShellCheck
make lint

# Common issues to fix:
# - SC2034: Unused variable (may need # shellcheck disable=SC2034)
# - SC2154: Variable referenced but not assigned (Zsh dynamic vars)
# - SC2155: Declare and assign separately for exit code checking
```

### Adding a Feature

1. **Check the spec**: Read `specs/002-pulsar-minimal-zsh/spec.md` to understand requirements
2. **Write tests first** (TDD encouraged):

   ```zsh
   # Edit tests/test-pulsar.md or create new test file
   # Add test cases for your feature
   ```

3. **Implement in pulsar.zsh**:
   - Add functions with clear comments
   - Follow existing naming conventions (kebab-case)
   - Keep functions focused (single responsibility)
4. **Test continuously**:

   ```zsh
   make test  # Run after each change
   ```

5. **Update documentation**:
   - README.md if user-facing
   - CHANGELOG.md with your change
   - Examples if needed

### Fixing a Bug

1. **Write a failing test** that reproduces the bug
2. **Fix the bug** in pulsar.zsh
3. **Verify test passes** with `make test`
4. **Update CHANGELOG.md** under "Fixed"

## Common Development Tasks

### Testing a Change Locally

```zsh
# Option 1: Source directly
source ./pulsar.zsh

# Option 2: Install for development
make install-dev  # Adds to your .zshrc
```

### Benchmarking Performance

```zsh
source ./pulsar.zsh

# Run built-in benchmark
pulsar-benchmark

# Manual timing
time (source ./pulsar.zsh)  # Should be <50ms
```

### Debugging

```zsh
# Enable Zsh tracing
set -x
source ./pulsar.zsh
plugin-load zsh-users/zsh-autosuggestions
set +x

# Check variables
print -l $PULSAR_PLUGINS
print -l $_pulsar_loaded_plugins

# Check paths
print -l $PULSAR_HOME/repos/*/*
```

### Adding a Test

Edit `tests/test-pulsar.md`:

````markdown
### Test Name

```zsh
$ command-to-run
expected output line 1
expected output line 2
$ echo $?  # Exit code check
0
```
````

## Understanding the Codebase

### Key Functions

```zsh
# Core API (public)
plugin-clone    # Clone plugins from git
plugin-load     # Load plugins into shell
plugin-update   # Update installed plugins
plugin-compile  # Compile to bytecode

# Self-management
pulsar-self-update   # Update pulsar itself
pulsar-doctor        # Validate environment
pulsar-benchmark     # Performance measurement

# Internal helpers (private, prefixed with pulsar__)
pulsar__expand_shorthand   # OMZP:: → ohmyzsh/ohmyzsh/plugins/
pulsar__find_entry_point   # Discover plugin.zsh, init.zsh, etc.
pulsar__cecho              # Colored output
```

### Code Organization

```zsh
# pulsar.zsh structure:
# 1. Version and config (lines 1-50)
# 2. Helper functions (lines 51-200)
# 3. Shorthand expansion (lines 201-250)
# 4. Core plugin functions (lines 251-600)
# 5. Update system (lines 601-800)
# 6. Utility commands (lines 801-1000)
# 7. Auto-run logic (lines 1001-1100)
```

### Testing Framework

Tests use clitest-style markdown format:

- **Commands**: Lines starting with `$`
- **Expected output**: Lines after command (exact match)
- **Setup/teardown**: Uses `__init__.zsh` for test harness
- **89 tests total**: ~2 minutes execution time

## SpecKit Workflow (Advanced)

Pulsar uses SpecKit for specification-driven development:

```zsh
# Create new feature spec
./.specify/scripts/bash/create-new-feature.sh "Feature description"

# Follow SpecKit commands (see .github/prompts/)
# - /speckit.specify - Create/update spec
# - /speckit.plan - Generate implementation plan
# - /speckit.tasks - Break down into tasks
# - /speckit.implement - Execute tasks
```

Current specs:

- **001-we-are-creating**: Original basic plugin manager
- **002-pulsar-minimal-zsh**: Comprehensive retrospective (current)

## Common Issues

### Tests Failing

```zsh
# Clean cache and retry
rm -rf ~/.cache/pulsar
make test
```

### ShellCheck Warnings

```zsh
# Disable specific checks with comments
# shellcheck disable=SC2154
local var=$UNDEFINED_VAR  # Zsh sets this dynamically
```

### Performance Regression

```zsh
# Benchmark before and after
pulsar-benchmark  # Target: <50ms overhead

# Profile with zprof
zmodload zsh/zprof
source ./pulsar.zsh
plugin-load $PULSAR_PLUGINS
zprof
```

## Release Process

1. **Update version** in pulsar.zsh (`PULSAR_VERSION`)
2. **Update CHANGELOG.md** with changes (follow SemVer categories)
3. **Commit version bump**:

   ```zsh
   git commit -am "chore: bump version to v0.X.Y"
   ```

4. **Create git tag**:

   ```zsh
   git tag -a v0.X.Y -m "Release v0.X.Y"
   git push origin v0.X.Y
   ```

5. **GitHub release**: Create release from tag with CHANGELOG excerpt

## Getting Help

### Resources

- **README.md**: User documentation
- **specs/002-pulsar-minimal-zsh/**: Complete specification
- **constitution.md**: Development principles
- **CHANGELOG.md**: Version history
- **examples/**: Usage examples

### Commands

```zsh
make help          # Show available make targets
pulsar-doctor      # Validate environment
make test          # Run test suite
make lint          # Run linting
```

### Questions

- **Issues**: Open GitHub issue
- **Discussions**: Use GitHub discussions
- **Constitution**: Check `.specify/memory/constitution.md` first

## Next Steps

1. ✅ Read the constitution (`.specify/memory/constitution.md`)
2. ✅ Run `make test` to verify setup
3. ✅ Try sourcing `pulsar.zsh` and loading a plugin
4. ✅ Read `specs/002-pulsar-minimal-zsh/spec.md` for requirements
5. ✅ Pick a feature or bug from GitHub issues
6. ✅ Create feature branch and start coding!

## Pro Tips

- **Always run tests before pushing**
- **Keep functions under 50 lines** (readability)
- **Add tests for new features** (required)
- **Update CHANGELOG.md** with every change
- **Follow conventional commits** (feat:, fix:, docs:)
- **Check performance** with `pulsar-benchmark`
- **Read existing code** for patterns and conventions
- **Ask before big changes** (open issue/discussion)

Welcome to Pulsar development! 🚀
