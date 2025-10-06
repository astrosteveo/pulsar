# Archive

This directory contains legacy implementations and examples from the zsh_unplugged project before the introduction of **Pulsar** as the primary micro plugin manager framework.

## What's Here

### Legacy Scripts

- **`zsh_unplugged.zsh`** - The original ~20 line `plugin-load` function that started it all
- **`unplugged.zsh`** - An early variant of the unplugged approach
- **`antidote.lite.zsh`** - The predecessor to Pulsar, now a compatibility shim that forwards to Pulsar

### Legacy Examples

The `examples/` subdirectory contains usage examples for the legacy scripts:

- `antidote_lite_example.zsh` - Example using the old antidote.lite
- `full_featured.zsh` - Full-featured example with the original approach
- `ohmyzsh_zshrc.zsh` / `ohmyzsh_zsh_custom_zshrc.zsh` - Oh-My-Zsh integration examples
- `prezto_zshrc.zsh` - Prezto framework integration example
- `zshrc.zsh` / `zshrc_clone.zsh` - Various .zshrc examples

## Why Archive?

With the introduction of **Pulsar**, the project has a clearer identity and more robust plugin management with features like:

- Parallel plugin cloning
- Built-in plugin compilation support
- Better plugin update workflow
- Cleaner variable naming (`PULSAR_HOME` vs `ANTIDOTE_LITE_HOME`)
- More intuitive API design

These legacy scripts are preserved for:

- Historical reference
- Learning purposes
- Users with existing configurations who aren't ready to migrate

## Migrating to Pulsar

If you're using any of these legacy scripts, migrating to Pulsar is straightforward:

1. Replace your script source with `pulsar.zsh`
2. Update environment variables if you've customized them:
   - `ANTIDOTE_LITE_HOME` → `PULSAR_HOME`
   - `ANTIDOTE_LITE_GITURL` → `PULSAR_GITURL`
3. The function names remain the same: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`

See the main [README.md](../README.md) and [examples/pulsar_example.zsh](../examples/pulsar_example.zsh) for current usage.
