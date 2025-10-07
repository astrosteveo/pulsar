# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and the project adheres to Semantic Versioning when releases are tagged.

## [Unreleased]

## [0.3.0] - 2025-10-07

### Changed

- Installer: do not set ZDOTDIR; only respect a pre-set ZDOTDIR (env or ~/.zshenv). Prefer ZDOTDIR for install targets only when present.
- Installer: prefer ZDOTDIR for `$ZSH` resolution; make curl optional; safe bootstrap sourcing; portable sed for legacy block removal.
- Tests: harden `substenv`; make VS Code shim assertion robust across clitest variants.
- README: clarify ZDOTDIR policy and behavior.

### Removed

- Legacy root files: .zshrc, debug_pulsar.zsh, unplugged.zsh, zsh_unplugged.zsh
- Directories: archive/, zsh_unplugged/
- Tests: tests/test-unplugged.md, tests/test-zsh-unplugged.md

## [0.2.0] - 2025-10-06

### Added

- Declarative autorun mode: configure plugins via `PULSAR_PLUGINS`, `PULSAR_PATH`, and `PULSAR_FPATH`; optional `PULSAR_AUTORUN`, `PULSAR_NO_AUTORUN`, and `PULSAR_AUTOCOMPILE` controls.
- Pinning support for `repo@ref` (branch/tag/commit) in `plugin-clone`.
- Prefer `$plugin/bin` for `plugin-load --kind path` when available.
- `PULSAR_FORCE_RECLONE` to force re-clone on demand.
- `pulsar-doctor` for quick environment checks.
- New `examples/pulsar_declarative.zsh` and simple `Makefile` with `test` and `release` targets.
- README polish with badges, examples, and clarified configuration.

### Changed

- Test harness: ensure `null_glob` and set `XDG_CACHE_HOME` during tests for stable behavior.

### Removed

- Legacy migration diffs and before/after comparisons (archive/ removed; legacy contents deleted).

## [0.1.0] - 2025-10-06

- Initial Pulsar extraction and documentation.

[Unreleased]: https://github.com/astrosteveo/pulsar/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/astrosteveo/pulsar/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/astrosteveo/pulsar/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/astrosteveo/pulsar/commits/main
