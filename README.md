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
    https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh
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
