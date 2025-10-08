<!--
Sync Impact Report - Constitution Update
=========================================
Version change: INITIAL → 1.0.0
Modified principles: N/A (initial version)
Added sections:
  - Core Principles (5 principles)
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  ✅ plan-template.md - Updated Constitution Check section
  ✅ spec-template.md - Aligned with quality standards
  ✅ tasks-template.md - Reflects branch workflow and testing discipline
Follow-up TODOs: None
=========================================
-->

# Pulsar Constitution

## Core Principles

### I. Branch-Based Workflow (NON-NEGOTIABLE)

**ALL development work MUST occur in feature branches. Direct commits to `main` are PROHIBITED.**

- Every task begins with creating a new feature branch from `main`
- Branch naming convention: `[###-feature-name]` where `###` is the feature/issue number
- All changes MUST be committed to the feature branch
- Once work is complete, all changes MUST be pushed to the remote repository
- A Pull Request (PR) MUST be opened for review before merging to `main`
- The `main` branch is protected and serves as the stable production baseline
- No exceptions: hotfixes, documentation updates, and configuration changes all follow this workflow

**Rationale**: Branch-based workflow enables code review, prevents breaking changes to production, maintains clean history, enables parallel development, and provides rollback capability. This is the foundation of professional software development practices.

### II. Code Quality Standards

**Code MUST be maintainable, readable, and follow established conventions.**

- Follow language-specific style guides (e.g., PEP 8 for Python, StandardJS for JavaScript)
- Use meaningful variable and function names that express intent
- Functions MUST have a single, clear purpose (Single Responsibility Principle)
- Code duplication MUST be eliminated through proper abstractions
- Comments MUST explain "why" not "what" - code should be self-documenting
- Linting and formatting tools MUST be configured and enforced
- Code complexity metrics MUST be monitored (cyclomatic complexity < 10 per function)
- Technical debt MUST be documented and tracked with clear remediation plans

**Rationale**: High-quality code reduces bugs, accelerates feature development, lowers maintenance costs, and enables team scalability. Quality is not optional—it's the foundation of sustainable software.

### III. Testing Standards

**Comprehensive testing MUST validate functionality, prevent regressions, and document behavior.**

- Test coverage MUST meet minimum thresholds: 80% for critical paths, 60% overall
- Tests MUST be organized by type: unit tests, integration tests, contract tests, end-to-end tests
- Each user story MUST have corresponding acceptance tests
- Tests MUST be written before or alongside implementation (Test-Driven Development encouraged)
- All tests MUST pass before merging to `main` - no exceptions
- Tests MUST be fast: unit tests < 100ms, integration tests < 5s, full suite < 5min
- Flaky tests MUST be fixed or quarantined immediately
- Test failures MUST block deployment

**Rationale**: Testing is our safety net. Comprehensive tests enable confident refactoring, prevent regressions, serve as living documentation, and ensure features work as specified.

### IV. User Experience Consistency

**User-facing functionality MUST provide consistent, predictable, and intuitive experiences.**

- CLI tools MUST follow standard conventions: stdin/args for input, stdout for output, stderr for errors
- Error messages MUST be clear, actionable, and user-friendly (not raw stack traces)
- Output formats MUST be consistent across similar operations
- Progress indicators MUST be shown for long-running operations
- Color and formatting MUST be configurable (auto-detect terminal capabilities)
- Documentation MUST include usage examples for common scenarios
- Breaking changes to user interfaces MUST be avoided or clearly communicated with migration guides
- User feedback (errors, warnings, confirmations) MUST be contextual and helpful

**Rationale**: Consistent UX reduces cognitive load, increases user productivity, decreases support burden, and builds user trust. Users should never be surprised or confused by interface changes.

### V. Performance Requirements

**Code MUST meet performance benchmarks and optimize for common use cases.**

- Performance-critical operations MUST have documented benchmarks
- Plugin loading MUST be optimized: parallel cloning, lazy loading, optional compilation
- CLI commands MUST respond within acceptable latency: interactive commands < 100ms, data operations < 1s
- Resource usage MUST be bounded: memory leaks MUST be prevented, CPU usage MUST be reasonable
- Performance regressions MUST be detected and prevented through automated benchmarking
- Scalability MUST be considered: operations should handle 100+ plugins efficiently
- Caching strategies MUST be employed where appropriate
- Performance optimizations MUST be measured and documented

**Rationale**: Performance directly impacts user satisfaction. Slow tools are abandoned tools. Optimization should be proactive, not reactive, and guided by measurement.

## Development Workflow

### Branch Management

1. **Create Branch**: `git checkout -b [###-feature-name]` from latest `main`
2. **Develop**: Make changes, commit frequently with clear messages
3. **Test**: Ensure all tests pass locally before pushing
4. **Push**: `git push origin [###-feature-name]`
5. **Pull Request**: Open PR with description linking to spec/task documentation
6. **Review**: Address feedback, update code, re-push to same branch
7. **Merge**: Once approved and CI passes, merge to `main` (squash or merge commit per project policy)
8. **Cleanup**: Delete feature branch after successful merge

### Commit Standards

- Commits MUST follow conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`
- Each commit MUST represent a logical unit of work
- Commit messages MUST be clear and descriptive
- Work-in-progress commits are acceptable in feature branches but MUST be cleaned up before merge

### Pull Request Requirements

- PR title MUST follow conventional commit format
- PR description MUST link to relevant spec/task documentation
- All CI checks MUST pass (tests, linting, type checking)
- At least one approving review MUST be obtained (for team projects)
- Constitution compliance MUST be verified during review

## Governance

### Constitution Authority

This constitution supersedes all other development practices and guidelines. When conflicts arise between this document and other guidance, this constitution takes precedence.

### Amendment Process

Amendments to this constitution require:

1. Proposed changes documented with rationale
2. Impact analysis on existing features and workflow
3. Team consensus (for team projects) or owner approval (for solo projects)
4. Version bump according to semantic versioning rules
5. Update of all dependent templates and documentation
6. Communication plan for breaking changes

### Compliance Review

- Every Pull Request MUST be reviewed for constitution compliance
- Violations MUST be justified with documented exceptions or corrected before merge
- Regular audits SHOULD be conducted to ensure ongoing compliance
- Constitution violations discovered in production MUST be tracked and remediated

### Versioning Policy

Constitution versions follow semantic versioning:

- **MAJOR**: Backward-incompatible governance changes, principle removals or redefinitions
- **MINOR**: New principles added, material expansions to existing principles
- **PATCH**: Clarifications, wording improvements, typo fixes

### Living Document

This constitution is a living document. As the project evolves, principles may be refined, added, or (rarely) removed. All changes MUST be documented in the Sync Impact Report and communicated to all stakeholders.

**Version**: 1.0.0 | **Ratified**: 2025-10-07 | **Last Amended**: 2025-10-07
