# Pulsar ⚡

> A micro Zsh plugin manager that's fast, simple, and gets out of your way.

**Pulsar** is a minimalist plugin manager for Zsh built on the philosophy that you don't need thousands of lines of code to manage your shell plugins. At ~100 lines of pure Zsh, Pulsar gives you everything you need: parallel cloning, automatic compilation, smart plugin detection, and blazing-fast loads.

## ✨ Features

- **Tiny** – ~100 lines of readable Zsh code
- **Fast** – Parallel plugin cloning and automatic compilation
- **Smart** – Auto-detects plugin init files and handles nested plugins
- **Simple** – Four functions: `plugin-clone`, `plugin-load`, `plugin-update`, `plugin-compile`
- **Compatible** – Works with any GitHub-hosted Zsh plugin
- **Zero dependencies** – Just Zsh and git

## 🚀 Quick Start

Add this to your `.zshrc`:

```zsh
# Setup vars
ZSH=${ZSH:-${ZDOTDIR:-$HOME/.config/zsh}}

# Download Pulsar if needed
if [[ ! -e $ZSH/lib/pulsar.zsh ]]; then
  mkdir -p $ZSH/lib
  curl -fsSL -o $ZSH/lib/pulsar.zsh \
    https://raw.githubusercontent.com/astrosteveo/zsh_unplugged/main/pulsar.zsh
fi

# Load Pulsar
source $ZSH/lib/pulsar.zsh

# Define your plugins
plugins=(
  sindresorhus/pure                 # prompt
  zsh-users/zsh-completions         # extra completions
  zsh-users/zsh-autosuggestions     # fish-like autosuggestions
  zsh-users/zsh-syntax-highlighting # syntax highlighting
)

# Load them
plugin-clone $plugins
plugin-load $plugins
```

That's it. Restart your shell and you're done.

## � Quick Reference

### Core functions

| Function | Description | Example |
|----------|-------------|---------|
| `plugin-clone` | Clone plugins in parallel | `plugin-clone user/repo` |
| `plugin-load` | Source a plugin (optionally adds to `path`/`fpath`) | `plugin-load user/repo` |
| `plugin-load --kind path` | Add executables to your `PATH` | `plugin-load --kind path romkatv/zsh-bench` |
| `plugin-load --kind fpath` | Add completions/prompts to `fpath` | `plugin-load --kind fpath sindresorhus/pure` |
| `plugin-update` | Pull the latest for every cloned plugin | `plugin-update` |
| `plugin-compile` | Compile plugins with `zrecompile` for faster loads | `plugin-compile` |

### Minimal `.zshrc`

```zsh
source ~/.config/zsh/lib/pulsar.zsh
plugin-clone zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting
plugin-load  zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting
```

### Full-featured `.zshrc`

```zsh
source ~/.config/zsh/lib/pulsar.zsh

utils=(romkatv/zsh-bench)
prompts=(sindresorhus/pure)
plugins=(
  zsh-users/zsh-completions
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

plugin-clone $utils $prompts $plugins

plugin-load --kind path $utils
plugin-load --kind fpath $prompts
plugin-load $plugins

autoload -U promptinit; promptinit
prompt pure
```

## 🧠 Usage Patterns

### Basic plugin management

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

### Advanced techniques

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

Example:

```zsh
export PULSAR_HOME=~/.local/share/pulsar
export PULSAR_GITURL=https://mirror.example.com/
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

## � Migration guides

### From antidote.lite

#### What changed

- `antidote.lite.zsh` → `pulsar.zsh`
- `ANTIDOTE_LITE_*` environment variables → `PULSAR_*`
- Cache directory moves from `~/.cache/antidote.lite` to `~/.cache/pulsar`

#### Migration steps

Use the compatibility shim (recommended):

```diff
- curl -fsSL -o $ZSH/lib/antidote.lite.zsh \
-   https://raw.githubusercontent.com/mattmc3/zsh_unplugged/main/antidote.lite.zsh
+ curl -fsSL -o $ZSH/lib/pulsar.zsh \
+   https://raw.githubusercontent.com/astrosteveo/zsh_unplugged/main/pulsar.zsh

- source $ZSH/lib/antidote.lite.zsh
+ source $ZSH/lib/pulsar.zsh
```

If you customised the environment, update the variable names:

```diff
- export ANTIDOTE_LITE_HOME=~/.local/share/antidote.lite
+ export PULSAR_HOME=~/.local/share/pulsar

- export ANTIDOTE_LITE_GITURL=https://mirror.example.com/
+ export PULSAR_GITURL=https://mirror.example.com/
```

#### Complete example

```zsh
# Before (antidote.lite)
if [[ ! -e $ZSH/lib/antidote.lite.zsh ]]; then
  mkdir -p $ZSH/lib
  curl -fsSL -o $ZSH/lib/antidote.lite.zsh \
    https://raw.githubusercontent.com/mattmc3/zsh_unplugged/main/antidote.lite.zsh
fi
export ANTIDOTE_LITE_HOME=~/.local/share/antidote.lite
source $ZSH/lib/antidote.lite.zsh
plugins=(zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting)
plugin-clone $plugins
plugin-load  $plugins

# After (Pulsar)
if [[ ! -e $ZSH/lib/pulsar.zsh ]]; then
  mkdir -p $ZSH/lib
  curl -fsSL -o $ZSH/lib/pulsar.zsh \
    https://raw.githubusercontent.com/astrosteveo/zsh_unplugged/main/pulsar.zsh
fi
export PULSAR_HOME=~/.local/share/pulsar
source $ZSH/lib/pulsar.zsh
plugins=(zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting)
plugin-clone $plugins
plugin-load  $plugins
```

### From zsh_unplugged

Pulsar splits cloning and loading into two functions and adds update/compile helpers:

```diff
- source zsh_unplugged.zsh
- plugin-load $plugins
+ source pulsar.zsh
+ plugin-clone $plugins   # optional – clones in parallel
+ plugin-load  $plugins
```

Use separate lists to control when things land on `PATH` versus `fpath`.

### From Oh-My-Zsh plugin management

```zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/lib/pulsar.zsh

external_plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)
plugin-clone $external_plugins
plugin-load  $external_plugins
```

### Common issues during migration

- **Plugins disappear** – Move `~/.cache/antidote.lite` to `~/.cache/pulsar`, or simply re-clone
- **Startup slows down** – Run `plugin-compile` and consider `romkatv/zsh-defer`
- **Missing pulsar.zsh** – Re-run the install curl command above

### Testing your migration

```zsh
echo $+functions[plugin-clone]    # -> 1
echo $+functions[plugin-load]     # -> 1
echo $+functions[plugin-update]   # -> 1
echo $+functions[plugin-compile]  # -> 1
echo $PULSAR_HOME                 # Confirms cache path
ls   $PULSAR_HOME                 # Lists installed plugins
```

### Rollback (if needed)

```zsh
cp archive/antidote.lite.zsh ~/.config/zsh/lib/
# or
cp archive/zsh_unplugged.zsh ~/.config/zsh/lib/
source ~/.config/zsh/lib/antidote.lite.zsh
```

## 📚 Examples

- [examples/pulsar_example.zsh](examples/pulsar_example.zsh) – Full-featured configuration
- [archive/examples/](archive/examples/) – Legacy setups preserved for reference

## 🗂️ Project structure

```text
.
├── pulsar.zsh                    # 🌟 Main Pulsar framework (~100 LOC)
├── README.md                     # 📖 This document
├── LICENSE                       # 📜 Unlicense (public domain)
├── .zshrc                        # 🔧 Sample config using Pulsar
├── examples/
│   └── pulsar_example.zsh        # 💡 Full-featured Pulsar example
├── tests/
│   ├── __init__.zsh              # 🧪 Test setup
│   ├── test-pulsar.md            # ✅ Pulsar-specific tests
│   ├── test-unplugged.md         # 📝 Legacy unplugged tests
│   ├── test-zsh-unplugged.md     # 📝 Legacy zsh_unplugged tests
│   └── test-advanced-zshrc.md    # 📝 Advanced config tests
└── archive/
    ├── README.md                 # 📚 Archive documentation
    ├── README.original.md        # 📜 Original README (preserved)
    ├── zsh_unplugged.zsh         # 🗄️ Original ~20 line function
    ├── unplugged.zsh             # 🗄️ Early variant
    ├── antidote.lite.zsh         # 🗄️ Compatibility shim
    └── examples/…                # Legacy examples
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

Pulsar builds on ideas from:

- [zsh_unplugged](archive/) – The original minimal approach
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
