# Pulsar ⚡

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-zsh%205.8%2B-777?logo=gnubash&logoColor=white)](https://www.zsh.org/)
[![Size](https://img.shields.io/badge/footprint-~100%20LOC-4caf50)](pulsar.zsh)
[![Changelog](https://img.shields.io/badge/keep-a%20changelog-0a7ea4)](CHANGELOG.md)
[![Release](https://img.shields.io/github/v/release/astrosteveo/pulsar?display_name=tag&sort=semver)](https://github.com/astrosteveo/pulsar/releases)

> A micro Zsh plugin manager that's fast, simple, and gets out of your way.

**Pulsar** is a minimalist plugin manager for Zsh built on the philosophy that you don't need thousands of lines of code to manage your shell plugins. At ~100 lines of pure Zsh, Pulsar gives you everything you need: parallel cloning, automatic compilation, smart plugin detection, and blazing-fast loads.

## ☝️ One-line install

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulsar/main/install.sh)"
```

Flags:

- `--channel=edge` to enable edge notices
- `--no-zdotdir` to keep existing ZDOTDIR layout

Note: The installer is idempotent. Re-running updates or repairs the single Pulsar block and avoids duplicates or extra backups beyond the first insertion.

What this does:

- Honors an existing ZDOTDIR (if you already export it). Pulsar no longer sets ZDOTDIR for you.
- Installs a minimal bootstrapper at `$ZDOTDIR/lib/pulsar-bootstrap.zsh`
- Fetches and refreshes [pulsar.zsh](pulsar.zsh:1) automatically using curl `-z`
- Safely appends a single guarded block to your zshrc (idempotent) using markers:
  - `# >>> pulsar >>>`
  - `# <<< pulsar <<<`
- Backs up files before changes
- Removes legacy Pulsar bootstrap from `~/.zshrc` (old non-guarded blocks, raw curl lines, and `source $ZSH/lib/pulsar.zsh`) to keep it clean
- Supports stable/edge channels via `--channel`

- ZDOTDIR-aware behavior:

- If you already have ZDOTDIR set (either in the environment or in your `~/.zshenv`), your primary shell config will be written to `$ZDOTDIR/.zshrc`.
- For compatibility with tools that still read `~/.zshrc` directly (notably VS Code integrated terminal), the installer writes a tiny shim to `~/.zshrc` that, when `TERM_PROGRAM=vscode`, re-sources `$ZDOTDIR/.zshrc`. This prevents issues when your real `zshrc` is not located at `~/.zshrc`.
  - The shim is wrapped with markers `# >>> pulsar-zdotdir-shim >>>` and `# <<< pulsar-zdotdir-shim <<<` and is maintained idempotently.
  - The shim is only installed if ZDOTDIR is already present; Pulsar does not set ZDOTDIR for you.

Best practice:

- If you want Pulsar to manage configuration outside of `~/.zshrc`, set `ZDOTDIR` to an explicit directory (for example, `${XDG_CONFIG_HOME:-$HOME/.config}/zsh`). If you set `ZDOTDIR=$HOME`, Pulsar treats that as effectively unset and falls back to the XDG default path.

Installer source: [install.sh](install.sh:1)

## ✨ Features

- **Tiny** – ~100 lines of readable Zsh code
- **Fast** – Parallel plugin cloning and automatic compilation
- **Smart** – Auto-detects plugin init files and handles nested plugins
- **Simple** – Four functions: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`
- **Compatible** – Works with any GitHub-hosted Zsh plugin
- **Zero dependencies** – Just Zsh and git

## 🚀 Quick Start

Add this to your `~/.zshrc` (no root .zshrc in repo):

```zsh
# ~/.zshrc starter (example)
export PULSAR_UPDATE_CHANNEL=stable
export PULSAR_UPDATE_CHECK_INTERVAL=86400
export PULSAR_UPDATE_NOTIFY=1
export PULSAR_REPO="astrosteveo/pulsar"

# clone once (choose a location you manage, e.g. XDG config)
# git clone https://github.com/astrosteveo/pulsar "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/pulsar"

# load Pulsar
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/pulsar/pulsar.zsh"

# declare plugins
myplugins=(
  zsh-users/zsh-completions
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  romkatv/zsh-bench
  sindresorhus/pure
)
```

That's it. Restart your shell and you're done.

## 🎥 Try Pulsar

Short demo of declarative setup and first-run clone (optional):

![Pulsar demo](assets/pulsar-demo.gif)

## 🧠 Usage Patterns

> Prefer declarative mode above. Manual mode is still available for full control.

### Basic plugin management (manual mode)

```zsh
# Clone plugins (happens in parallel)
plugin-clone user/repo another/plugin

# Load plugins
plugin-load user/repo another/plugin

# Update all plugins
plugin-update

# Compile plugins for extra speed
plugin-compile
```

### Advanced techniques (manual mode)

- **Pin to a specific commit**

  ```zsh
  plugin-clone zsh-users/zsh-autosuggestions@85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
  ```

- **Load utilities onto `PATH`**

  ```zsh
  plugin-clone romkatv/zsh-bench
  plugin-load --kind path romkatv/zsh-bench
  ```

- **Load prompts/completions into `fpath`**

  ```zsh
  plugin-clone sindresorhus/pure
  plugin-load --kind fpath sindresorhus/pure
  autoload -U promptinit; promptinit
  prompt pure
  ```

- **Defer loads for slower plugins**

  ```zsh
  plugin-clone romkatv/zsh-defer
  plugin-load romkatv/zsh-defer

  # Everything after this runs via zsh-defer
  plugin-load olets/zsh-abbr
  plugin-load zsh-users/zsh-autosuggestions
  ```

### Integration with frameworks

```zsh
# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
source $ZSH/lib/pulsar.zsh
plugin-clone zsh-users/zsh-autosuggestions
plugin-load  zsh-users/zsh-autosuggestions

# Local and remote plugins side-by-side
plugin-clone zsh-users/zsh-syntax-highlighting
plugin-load  zsh-users/zsh-syntax-highlighting
plugin-load  /path/to/my/local/plugin
```

## ⚙️ Configuration

Pulsar respects these environment variables:

- `PULSAR_HOME` – Where to store cloned plugins (default: `~/.cache/pulsar`)
- `PULSAR_GITURL` – Base URL for cloning (default: `https://github.com/`)
- `ZPLUGINDIR` – Additional plugin search path (default: `$ZSH_CUSTOM` or `$ZDOTDIR/plugins`)

- `PULSAR_PLUGINS` – Plugins to load normally (sourced)
- `PULSAR_PATH` – Plugins whose `bin`/executables should be added to `PATH`
- `PULSAR_FPATH` – Plugins to append to `fpath` (prompts/completions)
- `PULSAR_AUTORUN` – Force autorun even if arrays are empty at source time
- `PULSAR_NO_AUTORUN` – Disable autorun even if arrays are set
- `PULSAR_AUTOCOMPILE` – If set, run `plugin-compile` after loading
- `PULSAR_BANNER` – Show a one-line banner after autorun loads (auto|1|0; default: auto)

Update notifier variables:

- `PULSAR_UPDATE_CHANNEL` – stable|edge|off
- `PULSAR_UPDATE_CHECK_INTERVAL` – seconds
- `PULSAR_UPDATE_NOTIFY` – 0/1
- `PULSAR_REPO` – owner/repo

### Progress output

- `PULSAR_PROGRESS` – auto|1|0
  - auto: show progress only when stdout is a TTY
  - 1: always show progress
  - 0: never print progress
- `PULSAR_COLOR` – auto|1|0
  - auto: color only on TTY
  - 1: force color
  - 0: no color

Defaults: `PULSAR_PROGRESS=auto`, `PULSAR_COLOR=auto`.
If `PULSAR_BANNER` is `auto` or `1`, Pulsar prints a short “Pulsar ready” line on interactive terminals after autorun completes so users see visible confirmation.

Example:

```zsh
export PULSAR_HOME=~/.local/share/pulsar
export PULSAR_GITURL=https://mirror.example.com/

# Declarative setup
PULSAR_PLUGINS=(zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting)
# PULSAR_PATH=(romkatv/zsh-bench)
# PULSAR_FPATH=(sindresorhus/pure)
# PULSAR_AUTOCOMPILE=1
```

## 🛠 Maintenance

```zsh
# Update every plugin in place
plugin-update

# Compile all plugins for faster startup
plugin-compile

# Inspect what is installed
ls $PULSAR_HOME

# Remove a plugin (after removing it from your list)
rm -rf $PULSAR_HOME/user/plugin-name
```

## 🆘 Troubleshooting

### Plugin did not load

```zsh
ls $PULSAR_HOME                 # Confirm it was cloned
ls -la $PULSAR_HOME/user/plugin # Inspect plugin directory
ls $PULSAR_HOME/user/plugin/*.{plugin.zsh,zsh-theme,zsh,sh}
```

### Slow startup

```zsh
plugin-clone romkatv/zsh-defer
plugin-load  romkatv/zsh-defer
plugin-compile

# Benchmark with zsh-bench
plugin-clone romkatv/zsh-bench
plugin-load --kind path romkatv/zsh-bench
zsh-bench
```

### Start over from scratch

```zsh
rm -rf $PULSAR_HOME
# Restart Zsh and Pulsar will re-clone everything
```

## 🎯 Why Pulsar?

### The problem

- Some plugin managers are abandonware (antibody, zgen, zplug)
- Some disappear entirely (zinit by its original author)
- Many are thousands of lines of complex code
- A lot introduce performance issues or breaking changes

### The solution

Pulsar takes a different approach:

1. **Educational** – You can read and understand the entire codebase in minutes
2. **Stable** – Simple code means fewer bugs and no surprises
3. **Performant** – Parallel operations and compilation without complexity
4. **Self-sufficient** – Copy `pulsar.zsh` anywhere and you're done

## 📚 Examples

- [examples/pulsar_declarative.zsh](examples/pulsar_declarative.zsh) – Declarative, auto-load setup
- [examples/pulsar_example.zsh](examples/pulsar_example.zsh) – Full-featured manual configuration

## 🗂️ Project structure

```text
.
├── pulsar.zsh                    # 🌟 Main Pulsar framework (~100 LOC)
├── README.md                     # 📖 This document
├── LICENSE                       # 📜 Unlicense (public domain)
├── examples/
│   ├── pulsar_declarative.zsh    # 🧭 Declarative Pulsar example
│   └── pulsar_example.zsh        # 💡 Full-featured Pulsar example
├── tests/
│   ├── __init__.zsh              # 🧪 Test setup
│   ├── test-pulsar.md            # ✅ Pulsar-specific tests
│   └── test-advanced-zshrc.md    # 📝 Advanced config tests
```

## 📈 Future ideas

- Add installation demos (animated GIFs)
- Publish comparisons with other plugin managers
- Document common troubleshooting scenarios
- Add optional progress indicators during cloning
- Explore dependency resolution and health checks

## 📜 License

[Unlicense](LICENSE) – public domain. Use it anywhere, no attribution needed.

## 🙏 Credits

Pulsar builds on ideas from and acknowledges:

- [antidote](https://github.com/mattmc3/antidote) – Fast, functional plugin management
- [antibody](https://github.com/getantibody/antibody) – Parallel cloning inspiration
- The Zsh community – For creating amazing plugins

## 🔗 Related projects

- [antidote](https://github.com/mattmc3/antidote) – Full-featured manager by the original author
- [zgenom](https://github.com/jandamm/zgenom) – Fast, maintained fork of zgen
- [zinit-continuum](https://github.com/zdharma-continuum/zinit) – Community-maintained zinit
- [znap](https://github.com/marlonrichert/zsh-snap) – Git-based lightweight manager

---

**Made with ⚡ by [astrosteveo](https://github.com/astrosteveo)**
