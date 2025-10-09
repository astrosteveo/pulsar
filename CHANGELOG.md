# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and the project adheres to Semantic Versioning when releases are tagged.

## [Unreleased]

## [0.6.0] - 2025-10-08

### Added

- **Oh-My-Zsh Shorthand Aliases**: New convenient syntax for OMZ plugins:
  - `OMZP::plugin-name` expands to `ohmyzsh/ohmyzsh/plugins/plugin-name`
  - `OMZL::lib-name` expands to `ohmyzsh/ohmyzsh/lib/lib-name`
  - `OMZT::theme-name` expands to `ohmyzsh/ohmyzsh/themes/theme-name`
- **Automatic Completion Initialization**: Pulsar now auto-calls `compinit` when loading OMZ plugins to prevent `compdef: command not found` errors
- **Enhanced Error Messages**: Better error reporting for failed clones, missing init files, and ref checkout failures
- **Comprehensive OMZ/Prezto Documentation**: Added detailed guide at `docs/OMZ-PREZTO-GUIDE.md`
- **New Test Coverage**: Added `tests/test-omz-plugins.md` for OMZ plugin integration testing

### Changed

- **Improved Clone Messages**: Clone progress now shows full plugin path including subdirectories (e.g., "Cloning ohmyzsh/ohmyzsh/plugins/kubectl..." instead of just "Cloning ohmyzsh/ohmyzsh...")
- **Better OMZ Plugin Discovery**: Plugin loading now properly handles subdirectory paths in OMZ repository structure
- **Enhanced File Structure Detection**: Improved logic to distinguish between OMZ lib files, plugins, and themes

### Fixed

- `compdef: command not found` errors when loading Oh-My-Zsh plugins
- Confusing clone messages that didn't show subdirectory paths
- Missing error handling for failed git operations
- OMZ lib files not loading correctly (was looking for directories when files existed)
- Idempotency issues with repository cloning

## [0.5.0] - 2025-10-08

### Added

- **Parallel Plugin Management**: Clone and update plugins concurrently for improved performance
- **Automatic Init Discovery**: 5-step precedence for finding plugin entry points
- **Multiple Loading Modes**: Source, PATH, and fpath modes for different plugin types
- **Basic Oh-My-Zsh Compatibility**: Initial support for loading OMZ plugins
- **Version Pinning**: Pin plugins to specific tags, branches, or commits
- **Self-Update System**: Stable and unstable update channels with automatic notifications
- **Compilation Support**: Optional bytecode compilation via `zcompile` for faster loads
- **VS Code Integration**: Automatic ZDOTDIR shim for VS Code terminal support
- **Project Infrastructure**: EditorConfig, ShellCheck config, enhanced Makefile
- **Comprehensive Documentation**: Updated README with Quick Start, configuration, examples
- **Example Configurations**: Added declarative example and OMZ migration guide
- **Test Suite**: 89 integration tests covering core functionality
- **Benchmark Tool**: Added `pulsar-benchmark` function for performance measurement
- **Diagnostic Tool**: Added `pulsar-doctor` for environment checks

### Changed

- **Code Quality**: Implemented ShellCheck compliance, no linting errors
- **Error Handling**: Improved error messages and graceful degradation
- **Performance**: Bounded parallelism respecting CPU cores, <50ms overhead target
- **Installation**: Safe installation with timestamped backups and ZDOTDIR support

### Fixed

- Various edge cases in plugin loading and initialization
- ZDOTDIR handling in VS Code terminal
- Git operations error handling

## [0.4.0] - 2025-10-07

### Added

- Unified, ordered plugin list via `PULSAR_PLUGINS` supporting prefixes `path:` and `fpath:` and pinning with `@ref`. Load order now follows the array order.
- Version tracking via `PULSAR_VERSION` variable to enable better version comparison

### Changed

- Backward compatible: legacy `PULSAR_PATH` and `PULSAR_FPATH` continue to work; when present they take precedence over ordered mode.
- Installer `.zshrc` block now showcases the unified list.
- README modernized to reflect unified list, ZDOTDIR policy, and update notifier.
- Improved `pulsar-self-update` with better feedback and error handling to clearly show when updates succeed or fail

## [0.3.1] - 2025-10-07

### Fixed

- VS Code terminal sourcing: treat `ZDOTDIR=$HOME` as unset when computing install prefix and deciding whether to install the shim, so `$HOME/lib/pulsar-bootstrap.zsh` is never referenced. Compute `ZSH` in the inserted block to prefer XDG path when `ZDOTDIR=$HOME`.

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

[Unreleased]: https://github.com/astrosteveo/pulsar/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/astrosteveo/pulsar/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/astrosteveo/pulsar/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/astrosteveo/pulsar/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/astrosteveo/pulsar/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/astrosteveo/pulsar/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/astrosteveo/pulsar/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/astrosteveo/pulsar/commits/main
