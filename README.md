
# Pulsar ⚡

![GitHub License](https://img.shields.io/github/license/astrosteveo/pulsar)
![Shell](https://img.shields.io/badge/shell-zsh%205.8%2B-777?logo=gnubash&logoColor=white)
![Size](https://img.shields.io/badge/footprint-~477%20LOC-4caf50)
![Changelog](https://img.shields.io/badge/keep-a%20changelog-0a7ea4)
![Release](https://img.shields.io/github/v/release/astrosteveo/pulsar?display_name=tag&sort=semver)

---

**Pulsar** is a minimalist plugin manager for Zsh built on the philosophy that you don't need thousands of lines of code to manage your shell plugins. At just under ~500 lines of pure Zsh and Bash, Pulsar gives you everything you need to parallel cloning, automatic compilation, smart plugin detection, and blazing-fast loads.

## Install

### Installer Script

For those who wish to examine the script before executing it: [install.sh](install.sh).

> [!NOTE]
> It is recommended to review all bash scripts found online before running them to make sure there is no malicious intent.

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulsar/main/install.sh)"
```

Flags:

- `--channel=edge` to enable edge notices
- `--no-zdotdir` to keep existing ZDOTDIR layout

---

## ✨ Features

- **Tiny** – ~100 lines of readable Zsh code
- **Fast** – Parallel plugin cloning and automatic compilation
- **Smart** – Auto-detects plugin init files and handles nested plugins
- **Simple** – Four functions: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`
- **Compatible** – Works with any GitHub-hosted Zsh plugin; just add a repo to an array, and then load that array
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

### Update notifications

Pulsar can automatically check for updates and notify you when a new version is available. On each shell initialization, Pulsar compares your local version to the remote version based on the configured channel.

- `PULSAR_UPDATE_CHANNEL` – Update channel (default: `stable`)
  - `stable` – Check for new release tags; only notifies when remote version is newer than local
  - `edge` – Track the latest commit on the main branch (may be unstable)
  - `off` – Disable update checks
- `PULSAR_UPDATE_CHECK_INTERVAL` – Seconds between update checks (default: `86400` = 24 hours)
- `PULSAR_UPDATE_NOTIFY` – Enable/disable notifications (default: `1` = enabled)
- `PULSAR_REPO` – Repository to check for updates (default: `astrosteveo/pulsar`)

**How it works:**

- **Stable channel**: Pulsar fetches the latest release tag from GitHub and compares it to your local `PULSAR_VERSION` using semantic version comparison. You'll only be notified if a newer version is available.
- **Edge channel**: Pulsar fetches the latest commit SHA from the main branch and notifies you if it differs from the last seen SHA, allowing you to track cutting-edge updates (but potentially unstable).
- Update checks respect the configured interval to avoid excessive network requests.

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

# Update Pulsar itself (and plugins)
pulsar-self-update   # updates core script via curl and re-sources
pulsar-update        # self + plugins
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

- Many plugins begin development and become abandonware
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
