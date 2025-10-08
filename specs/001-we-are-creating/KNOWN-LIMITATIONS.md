# Known Limitations - Pulsar v1.0

**Status**: Documented for v1.0 MVP
**Review Date**: 2025-10-08
**Deferred To**: v2.0 (based on user feedback and real-world usage)

This document lists edge cases and scenarios that are **not explicitly handled** in Pulsar v1.0. These limitations are intentionally deferred to keep the initial implementation minimal (KISS principle) while delivering core value. They will be addressed in future versions based on user feedback and actual pain points.

---

## Edge Case Limitations

### 1. Zero Plugins (Empty Arrays)

**Limitation**: No explicit requirements for behavior when all plugin arrays are empty.

**Current Behavior**: Pulsar initializes successfully but does nothing (no-op). Shell startup overhead is minimal.

**Impact**: LOW - Edge case unlikely in practice (users install plugin manager to load plugins).

**Deferred Because**: Not a realistic user scenario; doesn't block core functionality.

**Future Consideration**: Add validation message if no plugins configured: "Pulsar loaded but no plugins defined."

---

### 2. Special Characters in Plugin Names

**Limitation**: No explicit handling for special characters (@, /, -, _) in plugin repository names beyond basic @ for version pins.

**Current Behavior**: Relies on git and filesystem to handle special characters; may fail unexpectedly.

**Impact**: MEDIUM - Some edge case plugin names might not clone correctly.

**Deferred Because**: Standard GitHub naming conventions avoid problematic characters; git handles most cases.

**Future Consideration**: Add validation and escaping for plugin names if users report issues.

---

### 3. Slow Network Timeouts

**Limitation**: No explicit timeout requirements for git operations during clone/update.

**Current Behavior**: Inherits git's default timeout behavior (usually 2-5 minutes).

**Impact**: LOW-MEDIUM - User may wait a long time for failed clones on slow networks.

**Deferred Because**: Git's defaults are reasonable; adding timeout logic adds complexity.

**Future Consideration**: Add `PULSAR_GIT_TIMEOUT` config variable if users request it.

---

### 4. Circular Symlinks in Subdirectories

**Limitation**: No requirements for detecting or handling circular symbolic links in cloned plugin directories.

**Current Behavior**: File system operations may hang or fail if circular symlinks exist.

**Impact**: LOW - Rare in real plugin repositories; git usually prevents this.

**Deferred Because**: Extremely rare edge case; adds complexity to validate every clone.

**Future Consideration**: Add symlink validation if users report issues with specific plugins.

---

### 5. Read-Only Filesystem

**Limitation**: No requirements for graceful handling when cache directory is on read-only filesystem.

**Current Behavior**: Fails with error when attempting to write to cache; may not provide helpful message.

**Impact**: LOW - Uncommon scenario; users typically have write access to home directory.

**Deferred Because**: Read-only home directories are extremely rare in interactive shell usage.

**Future Consideration**: Detect read-only filesystem and provide clear error message.

---

### 6. Non-Existent ZDOTDIR

**Limitation**: No explicit handling when `$ZDOTDIR` points to non-existent directory.

**Current Behavior**: FR-010 requires "graceful handling" but specifics undefined. Likely fails during .zshrc read.

**Impact**: LOW-MEDIUM - User configuration error; should be caught by Zsh itself.

**Deferred Because**: Zsh handles this at startup; Pulsar doesn't need to duplicate checks.

**Future Consideration**: Add validation if users report confusing error messages.

---

### 7. Git Version Compatibility

**Limitation**: No minimum git version specified; only requires "git in PATH" (ASM-002).

**Current Behavior**: Assumes modern git with parallel fetch support; may fail on very old versions.

**Impact**: LOW - Most systems have git 2.0+ which supports all required operations.

**Deferred Because**: Testing all git versions adds burden; document minimum if issues arise.

**Future Consideration**: Add minimum version check (e.g., git 2.0+) if users report incompatibilities.

---

### 8. Concurrent Git Operations

**Limitation**: No requirements for handling startup during active background git operations in cache.

**Current Behavior**: May conflict with manual git operations in plugin directories; race conditions possible.

**Impact**: LOW - Users rarely manually git-manipulate cached plugins during shell startup.

**Deferred Because**: Complex to implement git locking; real-world collision rate is negligible.

**Future Consideration**: Add advisory locks if users report cache corruption from concurrent access.

---

### 9. Very Large Repositories (>1GB)

**Limitation**: No handling for extremely large plugin repositories that consume excessive disk space or clone time.

**Current Behavior**: Clone proceeds normally but may take very long time or fill disk.

**Impact**: LOW - Plugin repositories are typically small (<10MB); large repos are rare.

**Deferred Because**: Not a realistic plugin use case; large repos should be system packages.

**Future Consideration**: Add warning for clones taking >60 seconds or >100MB.

---

### 10. Non-Standard Branch Names (beyond main/master)

**Limitation**: FR-006 supports "tags, branches, commits" but default branch assumption unclear for repos without main/master.

**Current Behavior**: Relies on git's default branch detection; should work for most cases.

**Impact**: LOW - GitHub now standardizes on 'main'; git handles default branch automatically.

**Deferred Because**: Git clone handles default branch correctly; no custom logic needed.

**Future Consideration**: No action needed unless users report issues.

---

## Testing Coverage

These limitations are **not tested** in the v1.0 test suite:

- **CHK045**: 0 plugins minimum boundary
- **CHK047**: Special characters in plugin names (@, /, -, _)
- **CHK048**: Slow network timeout behavior
- **CHK049**: Circular symlink handling
- **CHK050**: Read-only filesystem
- **CHK051**: Non-existent ZDOTDIR (partially covered by FR-010)
- **CHK052**: Git version compatibility range
- **CHK053**: Concurrent git operations
- **CHK054**: Non-standard branch names (partially covered by FR-006)
- Large repository handling (>1GB)

**Total Untested Edge Cases**: 10 scenarios

---

## Risk Assessment

**Overall Risk**: 🟢 **LOW**

- Most limitations affect rare edge cases unlikely in typical usage
- Core functionality (clone, load, update) has comprehensive coverage
- "Warn and continue" error handling mitigates impact of edge case failures
- Users can work around most issues via recovery flows (documented in spec.md)

**Recommended Action**: Ship v1.0 with documented limitations, gather user feedback, prioritize fixes based on real-world pain points in v2.0.

---

## Version 2.0 Considerations

When planning v2.0, prioritize limitations based on:

1. **User Reports**: Track which limitations users actually encounter
2. **Severity**: Address any HIGH impact issues first
3. **Frequency**: Fix commonly reported issues before rare edge cases
4. **Complexity**: Prefer simple fixes that maintain KISS principle

**Monitoring Plan**: Encourage users to report edge case issues via GitHub issues, tag as "limitation" for v2.0 planning.

---

## Related Documents

- `spec.md` - Functional requirements and edge case handling
- `checklists/implementation-quality.md` - Full quality checklist (CHK045-CHK054)
- `CHECKLIST-COMPLETION-REPORT.md` - Analysis of checklist status
- `plan.md` - Technical context and constraints
