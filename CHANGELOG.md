# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and the project adheres to Semantic Versioning when releases are tagged.

## [Unreleased]

 
### Added

- Declarative autorun mode: configure plugins via `PULSAR_PLUGINS`, `PULSAR_PATH`, and `PULSAR_FPATH`; optional `PULSAR_AUTORUN`, `PULSAR_NO_AUTORUN`, and `PULSAR_AUTOCOMPILE` controls.
- Quick Start uses declarative setup; manual mode retained for full control.
- README polish with badges, examples, and clarified configuration.

 
### Changed

- Test harness: ensure `null_glob` and set `XDG_CACHE_HOME` during tests for stable behavior.

 
### Removed

- Legacy migration diffs and before/after comparisons (kept in archive if needed).

 
## [0.1.0] - 2025-10-06

- Initial Pulsar extraction and documentation.

[Unreleased]: https://github.com/astrosteveo/pulsar/compare/main...HEAD
[0.1.0]: https://github.com/astrosteveo/pulsar/commits/main
