# Research & Design Decisions

**Feature**: 002-pulsar-minimal-zsh
**Date**: 2025-10-08
**Status**: Retrospective Documentation

## Overview

This document captures the key design decisions, technical choices, and alternatives considered during the implementation of Pulsar v0.6.0. Since this is retrospective documentation, these decisions have already been implemented and validated through usage.

## Key Decisions

### Decision 1: Pure Zsh Implementation

**Decision**: Implement entirely in Zsh shell script with no external runtime dependencies (Python, Ruby, Node.js, etc.)

**Rationale**:

- Minimizes dependencies (users already have Zsh)
- No version management overhead (no virtual envs, no node_modules)
- Faster startup (no interpreter initialization)
- Simpler installation (single file copy)
- Better integration with shell environment
- Follows KISS principle

**Alternatives Considered**:

- **Python-based implementation**: Rejected due to dependency overhead, version conflicts, virtual environment complexity
- **Go/Rust compiled binary**: Rejected due to cross-platform compilation requirements, larger binary size, harder contribution barrier
- **Mixed approach (Zsh + Python)**: Rejected due to increased complexity and dependency management

**Trade-offs**:

- Pro: Zero runtime dependencies beyond Zsh and git
- Pro: ~50ms overhead achievable with pure shell
- Con: Limited to shell scripting capabilities
- Con: More verbose than high-level languages for some operations

### Decision 2: Single File Architecture

**Decision**: Keep all functionality in a single `pulsar.zsh` file (~1100 LOC)

**Rationale**:

- Simplest possible distribution (one file to source)
- No sourcing order dependencies
- Easy to inspect and understand
- Simpler testing (single entry point)
- Follows antidote's proven pattern
- Easy backup and version control

**Alternatives Considered**:

- **Multi-file modular structure**: Rejected due to sourcing complexity, load order issues, harder distribution
- **Autoload functions**: Rejected due to fpath pollution, discoverability issues

**Trade-offs**:

- Pro: Distribution simplicity
- Pro: No load order issues
- Con: Larger single file
- Con: Harder to navigate without good editor tools
- Mitigation: Clear function organization with comment headers, section markers

### Decision 3: XDG Base Directory Compliance

**Decision**: Use XDG_CACHE_HOME for plugin storage, respect all XDG variables

**Rationale**:

- Modern Linux/Unix standard
- User-controllable cache location
- Separates cache from config
- Prevents home directory pollution
- Better for containerized environments

**Alternatives Considered**:

- **Fixed ~/.pulsar directory**: Rejected as non-standard, harder to manage in containers
- **ZSH_CUSTOM location**: Rejected due to OMZ-specific assumption

**Trade-offs**:

- Pro: Standards-compliant
- Pro: User-configurable
- Pro: Better container support
- Con: Slightly more complex path logic
- Con: Users may not be familiar with XDG

### Decision 4: Parallel Operations with Bounded Concurrency

**Decision**: Clone and update plugins in parallel, bounded by CPU core count

**Rationale**:

- 3x+ speedup for typical plugin counts
- Network I/O is primary bottleneck (not CPU)
- Bounded concurrency prevents resource exhaustion
- Zsh job control provides native parallelism
- Critical for user experience with 10+ plugins

**Alternatives Considered**:

- **Sequential operations**: Rejected as too slow (10 plugins = 30+ seconds)
- **Unbounded parallelism**: Rejected due to resource exhaustion risk
- **Fixed parallelism (e.g., 4 jobs)**: Rejected as less optimal than CPU-based scaling

**Trade-offs**:

- Pro: Significant performance improvement
- Pro: Adapts to system capabilities
- Con: More complex error handling
- Con: Terminal output interleaving requires careful management

### Decision 5: Oh-My-Zsh Shorthand Aliases

**Decision**: Implement OMZP::, OMZL::, OMZT:: shortcuts that expand to ohmyzsh/ohmyzsh paths

**Rationale**:

- Familiarity for OMZ users (largest user base)
- Reduces migration friction
- Shorter configuration syntax
- Clear semantic meaning
- Easy to understand and remember

**Alternatives Considered**:

- **Full paths only**: Rejected due to verbosity, harder OMZ migration
- **Generic shorthand system**: Rejected as over-engineering for primary use case
- **Config-based aliases**: Rejected as adding complexity for minimal benefit

**Trade-offs**:

- Pro: Excellent OMZ migration experience
- Pro: Shorter, clearer configuration
- Con: Slight increase in code complexity
- Con: OMZ-specific knowledge required
- Mitigation: Extended to Prezto with PREZ:: for consistency

### Decision 6: Automatic Entry Point Discovery

**Decision**: 5-step precedence for finding plugin initialization files

**Precedence Order**:

1. `plugin.zsh` (explicit plugin marker)
2. `init.zsh` (common convention)
3. `*.plugin.zsh` (OMZ plugin pattern)
4. `*.zsh` (first alphabetically)
5. Error if none found

**Rationale**:

- 95% of plugins work without manual configuration
- Follows community conventions
- OMZ compatibility critical
- Predictable behavior
- Clear error messages when ambiguous

**Alternatives Considered**:

- **Manual specification required**: Rejected as poor UX, verbose config
- **Single fixed filename**: Rejected due to ecosystem diversity
- **Heuristics-based detection**: Rejected as unpredictable

**Trade-offs**:

- Pro: Excellent auto-detection success rate
- Pro: Works with OMZ, Prezto, and standalone plugins
- Con: Ambiguity possible with multiple .zsh files
- Mitigation: Clear precedence rules, manual override available

### Decision 7: Version Pinning with Git Refs

**Decision**: Support `repo@ref` syntax where ref can be tag, branch, or commit SHA

**Rationale**:

- Production stability requirement
- Team synchronization (everyone on same versions)
- Testing specific plugin versions
- Rollback capability
- Common pattern in package managers

**Alternatives Considered**:

- **No version pinning**: Rejected as unsuitable for production use
- **Tag-only pinning**: Rejected as too restrictive (some repos use branches)
- **Separate config format**: Rejected as less elegant than inline syntax

**Trade-offs**:

- Pro: Production-ready stability
- Pro: Flexible (tags, branches, commits)
- Pro: Simple syntax
- Con: Slightly more complex git operations
- Con: Users must understand git refs

### Decision 8: Self-Update System with Channels

**Decision**: Implement self-update with stable/edge/off channels, update notifications

**Rationale**:

- Keeps users current with bug fixes
- Low friction (single command update)
- Channel system provides safety (stable) and early access (edge)
- Notifications maintain project momentum
- Common pattern in modern tools

**Alternatives Considered**:

- **Manual update only**: Rejected as friction increases abandonment
- **Automatic updates**: Rejected as potentially surprising, requires more trust
- **Single channel**: Rejected as developers need edge access

**Trade-offs**:

- Pro: Easy to stay current
- Pro: Choice of stability vs. features
- Pro: Non-intrusive notifications
- Con: Additional code complexity
- Con: GitHub API dependency (gracefully degrades)

### Decision 9: Multiple Loading Modes

**Decision**: Support source (default), PATH, and fpath loading modes

**Rationale**:

- Flexibility for different plugin types
- Some plugins are binary tools (PATH mode)
- Some plugins are completion-only (fpath mode)
- Source mode covers 90% of use cases
- Follows antidote pattern

**Alternatives Considered**:

- **Source-only**: Rejected as limiting for binary/completion plugins
- **Complex mode system**: Rejected as over-engineering

**Trade-offs**:

- Pro: Handles diverse plugin types
- Pro: Simple prefix syntax (path:, fpath:)
- Con: Additional code paths
- Con: Users must understand modes
- Mitigation: Source mode as sensible default

### Decision 10: Optional Bytecode Compilation

**Decision**: Provide PULSAR_AUTOCOMPILE flag for .zwc generation

**Rationale**:

- 20%+ load time improvement when enabled
- Optional (not forced on users)
- Simple on/off flag
- Zsh native feature (zcompile)
- Beneficial for large plugin counts

**Alternatives Considered**:

- **Always compile**: Rejected as adds complexity, potential issues
- **No compilation support**: Rejected as leaving performance on table
- **Automatic compilation**: Rejected due to file permission issues in some setups

**Trade-offs**:

- Pro: Measurable performance improvement
- Pro: Optional (safe default)
- Con: Additional .zwc file management
- Con: Stale bytecode if files edited manually

## Technology Stack Decisions

### Testing Framework

**Decision**: Native Zsh test framework (clitest-style integration tests)

**Rationale**:

- No external test framework dependencies
- Integration tests more valuable than unit tests for shell scripts
- Tests execute actual commands in real environment
- Simple markdown-based test format
- Tests serve as documentation

**Alternatives Considered**:

- **shUnit2/zunit**: Rejected as external dependencies
- **bats**: Rejected as Bash-specific, requires installation
- **Manual testing only**: Rejected as unsustainable

### Linting

**Decision**: ShellCheck with Zsh-specific configuration

**Rationale**:

- Industry standard shell script linter
- Catches common errors
- Integrates with CI/CD
- Good Zsh support
- Editor integration available

### Documentation

**Decision**: Comprehensive README.md + examples/ + docs/ + in-code comments

**Rationale**:

- Multiple learning styles (reference, examples, guides)
- Progressive disclosure (simple → advanced)
- OMZ-PREZTO-GUIDE.md critical for migration
- Examples provide copy-paste starting points

## Performance Optimizations

### Parallel Cloning Strategy

**Implementation**: Background jobs with wait loop, bounded by CPU cores

**Benchmark Results**:

- 10 plugins sequential: ~30 seconds
- 10 plugins parallel (4 cores): ~10 seconds
- 3x speedup achieved

### Caching Strategy

**Implementation**: Clone once to XDG_CACHE_HOME, reuse across sessions

**Impact**: Subsequent shell startups near-instant for plugin loading (no network)

### Optional Compilation

**Implementation**: zcompile for .zwc bytecode generation

**Benchmark Results**: 20-30% faster sourcing with compilation enabled

## Security Considerations

### Git Repository Trust

**Approach**: User explicitly declares plugins (no automatic discovery)

**Rationale**: Users consciously choose to trust plugin sources

### No Arbitrary Code Execution

**Approach**: Only source files within cloned plugin directories

**Rationale**: Prevents injection attacks

### Update Verification

**Approach**: Git operations use standard git security (SSH keys, HTTPS)

**Rationale**: Leverage git's proven security model

## User Experience Design

### Principle 1: Sensible Defaults

- Auto-detect TTY for colored output
- Source mode as default
- Stable update channel as default
- Automatic entry point discovery

### Principle 2: Progressive Disclosure

- Simple configuration works immediately
- Advanced features opt-in
- Clear error messages guide users

### Principle 3: OMZ Migration Path

- Familiar shorthand syntax
- Comprehensive migration guide
- Examples demonstrate equivalent configurations

### Principle 4: Non-Intrusive

- Update notifications are optional
- Banner output off by default
- Respects NO_COLOR environment variable
- Silent in non-interactive shells

## Lessons Learned (Retrospective)

### What Worked Well

1. **Single file architecture**: Distribution simplicity worth the navigation tradeoff
2. **Parallel operations**: 3x speedup critical for adoption
3. **OMZ shortcuts**: Dramatically reduced migration friction
4. **XDG compliance**: No user complaints, containerization benefits
5. **Comprehensive testing**: 89 tests caught regressions during development

### What Could Be Improved

1. **Documentation organization**: Could benefit from better structure/navigation
2. **Error messages**: Some could be more actionable
3. **Performance monitoring**: Better built-in diagnostics needed
4. **Plugin ecosystem**: Need plugin recommendations/curated list

### Future Considerations

1. **Plugin ecosystem registry**: Central plugin discovery
2. **Conflict detection**: Warn about plugins that override same functions
3. **Dependency management**: Handle plugin inter-dependencies
4. **Health checks**: Automated plugin validation
5. **Migration tools**: Automated OMZ/Prezto config conversion

## References

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Semantic Versioning](https://semver.org)
- [ShellCheck](https://www.shellcheck.net)
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [antidote plugin manager](https://github.com/mattmc3/antidote) (inspiration)
- [Oh-My-Zsh](https://ohmyz.sh)
- [Prezto](https://github.com/sorin-ionescu/prezto)
