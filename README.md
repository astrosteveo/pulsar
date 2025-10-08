
# Pulsar ⚡

> A minimal, KISS-principle Zsh plugin manager. Fast, simple, and powerful.

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

## Features

- **⚡ Fast**: Sub-50ms startup overhead, parallel plugin cloning
- **🎯 Simple**: Declarative arrays, automatic init file discovery
- **🔧 Flexible**: Multiple loading modes (source, PATH, fpath)
- **📦 Compatible**: Oh-my-zsh plugins without installing oh-my-zsh
- **🚀 Minimal**: Pure Zsh + git only, <1000 lines of code

## Quick Start

### Installation

```bash
# One-liner installation
sh -c "$(curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulsar/main/install.sh)"
```

Or manually:

```bash
git clone https://github.com/astrosteveo/pulsar.git
cd pulsar
./install.sh
```

### Basic Usage

Add to your `.zshrc`:

```zsh
# Load Pulsar
source ~/.config/zsh/pulsar.zsh

# Declare plugins
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)

# Load plugins
plugin-load
```

Restart your shell and plugins will clone in parallel on first run, then load instantly.

## Configuration

### Plugin Arrays

**PULSAR_PLUGINS** - Source plugins (traditional loading):
```zsh
PULSAR_PLUGINS=(
  romkatv/powerlevel10k
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
```

**PULSAR_PATH** - Add tools to PATH:
```zsh
PULSAR_PATH=(
  junegunn/fzf
  sharkdp/fd
)
```

**PULSAR_FPATH** - Add completions to fpath:
```zsh
PULSAR_FPATH=(
  zsh-users/zsh-completions
)
```

### Oh-My-Zsh Plugins

Use subdirectory syntax to load OMZ plugins without installing OMZ:

```zsh
PULSAR_PLUGINS=(
  ohmyzsh/ohmyzsh/plugins/git
  ohmyzsh/ohmyzsh/plugins/docker
  ohmyzsh/ohmyzsh/plugins/kubectl
)
```

### Version Pinning

Pin plugins to specific versions:

```zsh
PULSAR_PLUGINS=(
  romkatv/powerlevel10k@v1.19.0
  zsh-users/zsh-syntax-highlighting@master
)
```

### Local Plugins

Use local plugin directories:

```zsh
PULSAR_PLUGINS=(
  /path/to/my/custom-plugin
)
```

## Manual Control

For power users who want direct control:

```zsh
# Clone a plugin
plugin-clone user/repo

# Force re-clone (useful for corrupted cache)
plugin-clone --force user/repo

# Load a plugin manually
plugin-load user/repo

# Update all plugins
plugin-update

# Compile plugins for faster loading
plugin-compile

# Check for plugin conflicts
pulsar-check-conflicts

# Update Pulsar itself
pulsar-self-update

# Update everything (Pulsar + all plugins)
pulsar-update
```

## Environment Variables

Customize Pulsar behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `PULSAR_HOME` | `$XDG_CACHE_HOME/pulsar` | Plugin cache location |
| `PULSAR_MAX_JOBS` | CPU cores | Max parallel clones |
| `PULSAR_UPDATE_CHANNEL` | `stable` | Update channel (`stable`/`unstable`/`off`) |
| `PULSAR_DEBUG` | `0` | Show debug output |
| `PULSAR_QUIET` | `0` | Suppress warnings |
| `PULSAR_COLOR` | `auto` | Use color output |
| `PULSAR_PROGRESS` | `auto` | Show progress indicators |

## Examples

See the [examples/](examples/) directory for complete configurations:

- [pulsar_declarative.zsh](examples/pulsar_declarative.zsh) - Simple declarative setup
- [pulsar_example.zsh](examples/pulsar_example.zsh) - Full-featured manual control
- [omz_migration.zsh](examples/omz_migration.zsh) - Migrating from oh-my-zsh

## Performance

Pulsar is designed for speed:

- **Plugin manager overhead**: <50ms (initialization only)
- **Parallel cloning**: 10 plugins in <10 seconds
- **Scales efficiently**: 100+ plugins supported
- **Compiled plugins**: Use `plugin-compile` for even faster loading

## Troubleshooting

### Plugin won't load?

```bash
# Check for conflicts
pulsar-check-conflicts

# Force re-clone
plugin-clone --force user/repo

# Enable debug mode
PULSAR_DEBUG=1 zsh
```

### Restore from backup

If installation causes issues:

```bash
# Backups are timestamped
cp ~/.zshrc.backup.YYYYMMDD-HHMMSS ~/.zshrc
```

### Clear cache

```bash
rm -rf ${XDG_CACHE_HOME:-$HOME/.cache}/pulsar
```

## Why Pulsar?

- **Minimal**: No external runtimes (Python, Ruby, Node.js)
- **KISS**: Single file implementation, easy to understand
- **Fast**: Parallel operations, compiled bytecode support
- **Compatible**: Works with existing Zsh plugins and OMZ plugins
- **Safe**: Automatic backups, graceful error handling
- **Flexible**: Declarative arrays + manual control

## License

This is free and unencumbered software released into the public domain.

See [LICENSE](LICENSE) or <http://unlicense.org/> for details.

## Credits

Inspired by [mattmc3/zsh_unplugged](https://github.com/mattmc3/zsh_unplugged) and the Zsh plugin management ecosystem. ⚡

![GitHub License](https://img.shields.io/github/license/astrosteveo/pulsar)
![Shell](https://img.shields.io/badge/shell-zsh%205.8%2B-777?logo=gnubash&logoColor=white)
![Changelog](https://img.shields.io/badge/keep-a%20changelog-0a7ea4)
![Release](https://img.shields.io/github/v/release/astrosteveo/pulsar?display_name=tag&sort=semver)

Minimal, fast, no-drama Zsh plugin management. Pulsar focuses on doing a few things well: parallel cloning, smart init discovery, optional declarative loading, and a tiny footprint you can actually read.

---

## Highlights

- Fast by default – parallel clone and optional compilation
- Simple mental model – four core commands: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`
- Smart init discovery – finds common init files automatically
- Declarative or manual – choose arrays for convenience or call functions directly
- GitHub-first – works with any repo like `owner/name`; local paths work too
- No bloat – just Zsh and git; curl is optional for self-update

## Requirements

- Zsh 5.8+
- git
- curl (optional, used by installer and self-update)

## Install

Review the script before running if you like: `install.sh`.

One-liner:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulsar/main/install.sh)"
```

Flags:

- `--channel=unstable` – opt into unstable update notices (legacy `edge` accepted)
- `--no-zdotdir` – keep your existing ZDOTDIR layout (no extra shim)

What the installer does:

- Writes a small bootstrap to `$ZSH/lib/pulsar-bootstrap.zsh` where `ZSH` resolves to:
  - `$ZDOTDIR` if set and different from `$HOME`, otherwise `${XDG_CONFIG_HOME:-$HOME/.config}/zsh`
- Inserts a guarded block into your primary `.zshrc` that:
  - Sets sensible defaults (`PULSAR_*`)
  - Declares example arrays you can edit
  - Sources `"$ZSH/lib/pulsar-bootstrap.zsh"`
- If your `ZDOTDIR` points away from `$HOME`, adds a tiny VS Code shim to `~/.zshrc` so VS Code shells pick up your real config.

The installer never sets `ZDOTDIR`; it only respects one you already use (from env or `~/.zshenv`).

## Quick start (declarative)

Edit the Pulsar block in your `.zshrc` or add something like this:

```zsh
# Resolve ZSH like the installer
if [[ -n ${ZDOTDIR-} && $ZDOTDIR != $HOME ]]; then
  ZSH=$ZDOTDIR
else
  ZSH=${XDG_CONFIG_HOME:-$HOME/.config}/zsh
fi

export PULSAR_PROGRESS=auto
export PULSAR_COLOR=auto
export PULSAR_BANNER=auto
export PULSAR_UPDATE_CHANNEL=stable  # stable|unstable|off ("edge" accepted)
export PULSAR_UPDATE_NOTIFY=1
export PULSAR_REPO="astrosteveo/pulsar" # point to a fork if you want

# Declarative arrays
PULSAR_PLUGINS=(
  zsh-users/zsh-completions
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
PULSAR_FPATH=(sindresorhus/pure)
PULSAR_PATH=(romkatv/zsh-bench)

source "$ZSH/lib/pulsar-bootstrap.zsh"
```

Open a new shell. Pulsar will clone in parallel and load your plugins. If interactive, you’ll see a tiny banner confirming it’s ready.

## Manual mode (full control)

```zsh
# Clone (parallel)
plugin-clone user/repo another/plugin

# Load init files
plugin-load user/repo another/plugin

# Update and compile
plugin-update
plugin-compile
```

Tips:

- Pin a branch/tag/commit: `plugin-clone owner/repo@v1.2.3` or `@deadbeef`
- Add tools to PATH: `plugin-load --kind path romkatv/zsh-bench`
- Add completions/prompts to fpath: `plugin-load --kind fpath sindresorhus/pure`
- Defer loads: `plugin-load romkatv/zsh-defer` then load slower plugins

## Configuration

Core paths and sources:

- `PULSAR_HOME` – clone destination (default: `${XDG_CACHE_HOME:-$HOME/.cache}/pulsar`)
- `PULSAR_GITURL` – base URL for clones (default: `https://github.com/`)
- `ZPLUGINDIR` – extra lookup path (default: `$ZSH_CUSTOM` or `$ZDOTDIR/plugins`)

Declarative arrays:

- `PULSAR_PLUGINS` – regular plugin repos to source
- `PULSAR_PATH` – repos to put on `PATH` (uses `bin/` when present)
- `PULSAR_FPATH` – repos to append to `fpath` (prompts/completions)

Autorun and output:

- `PULSAR_AUTORUN` – force autorun of declarative arrays
- `PULSAR_NO_AUTORUN` – disable autorun even if arrays are set
- `PULSAR_AUTOCOMPILE` – compile after loading if set
- `PULSAR_PROGRESS` – `auto|1|0` (default: `auto`)
- `PULSAR_COLOR` – `auto|1|0` (default: `auto`)
- `PULSAR_BANNER` – `auto|1|0` (default: `auto`)

Update notifier:

- `PULSAR_UPDATE_CHANNEL` – `stable|unstable|off` (default: `stable`). The old name `edge` is still accepted as an alias for `unstable`.

Deprecation note for `edge`

- The historically-used channel name `edge` is now deprecated in favor of `unstable`. Pulsar will continue to accept `edge` as an alias for `unstable` for now and will show a one-time deprecation notice when `edge` is in use.
- When Pulsar reaches v1.0, if your config still uses `edge` we will automatically migrate it to `unstable` for you and write a small marker to Pulsar's cache to record the migration. You are encouraged to update your `.zshrc` now to use `unstable` instead.
- `PULSAR_UPDATE_CHECK_INTERVAL` – seconds between checks (default: `86400`)
- `PULSAR_UPDATE_NOTIFY` – `0|1` enable notices (default: `1`)
- `PULSAR_REPO` – `owner/repo` for upstream checks and self-update (default: `astrosteveo/pulsar`)

Advanced:

- `PULSAR_FORCE_RECLONE` – re-clone requested repos even if they exist

## Updates and self-update

Pulsar can notify you about new releases (stable) or new commits on `main` (unstable). Notices are cached under `${XDG_CACHE_HOME:-$HOME/.cache}/pulsar` to avoid frequent checks. You’ll also see a one-time message when your local Pulsar version changes. The legacy name `edge` is accepted as an alias for `unstable`.

Handy commands:

- `pulsar-self-update` – fetches latest `pulsar.zsh` from `PULSAR_REPO` and re-sources it (uses curl if available)
- `pulsar-update` – self-update + `plugin-update`

Interactive update behavior

- When Pulsar detects a newer release (stable) or a new `main` commit (unstable) it will print a concise notification.
- On interactive shells Pulsar will optionally (default: enabled) prompt you to perform the self-update immediately. Set `PULSAR_UPDATE_PROMPT=0` to disable the interactive prompt.
- If enabled and available, Pulsar will attempt to fetch and display the release notes for stable releases before prompting. This requires `curl` and `python3` to be present.
- Control whether release notes are fetched with `PULSAR_UPDATE_SHOW_NOTES=0|1`.

## ZDOTDIR policy and VS Code

- Pulsar never sets `ZDOTDIR`. It honors an existing one from your environment or `~/.zshenv`.
- When `ZDOTDIR` equals `$HOME`, Pulsar treats it as “unset” for path resolution and uses `${XDG_CONFIG_HOME:-$HOME/.config}/zsh`.
- If `ZDOTDIR` points away from `$HOME`, the installer adds a small shim to `~/.zshrc` so VS Code (which reads `~/.zshrc`) re-sources your real config.

## Maintenance

```zsh
plugin-update       # update all plugins
plugin-compile      # compile init files for faster startup
pulsar-update       # self + plugins
```

## Uninstall

1) Remove the guarded Pulsar block from your `.zshrc` and (if present) the VS Code shim block in `~/.zshrc`.
2) Delete the bootstrap file: `rm -f "$ZSH/lib/pulsar-bootstrap.zsh"`.
3) Optionally remove cached plugins: `rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/pulsar"`.

## Examples

- `examples/pulsar_declarative.zsh` – declarative auto-load setup
- `examples/pulsar_example.zsh` – full-featured manual configuration

## License

[Unlicense](LICENSE) – public domain. Use it anywhere, no attribution needed.

## Credits

Ideas and inspiration:

- [antidote](https://github.com/mattmc3/antidote) – fast, functional plugin management
- [antibody](https://github.com/getantibody/antibody) – parallel cloning inspiration
- The Zsh community – for a wealth of great plugins

## Related projects

- [antidote](https://github.com/mattmc3/antidote)
- [zgenom](https://github.com/jandamm/zgenom)
- [zinit-continuum](https://github.com/zdharma-continuum/zinit)
- [znap](https://github.com/marlonrichert/zsh-snap)

---

Made with ⚡ by [astrosteveo](https://github.com/astrosteveo)
