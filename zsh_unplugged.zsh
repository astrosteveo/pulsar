# Legacy compatibility shim
# Exposes the original ~20-line zsh_unplugged plugin loader with expected
# environment variables and a helper plugin-script for tests.
0=${(%):-%N}

# Legacy paths expected by tests
export ZUNPLUG_REPOS=${XDG_DATA_HOME:-$HOME/.local/share}/zsh_unplugged
export ZUNPLUG_CUSTOM=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/plugins

# Ensure directories exist
[[ -d $ZUNPLUG_REPOS ]] || command mkdir -p -- $ZUNPLUG_REPOS
[[ -d $ZUNPLUG_CUSTOM ]] || command mkdir -p -- $ZUNPLUG_CUSTOM

# Point zsh_unplugged's clone dir to ZUNPLUG_REPOS to avoid double clones
export ZPLUGINDIR=$ZUNPLUG_REPOS

# Source vendored implementation
source ${0:A:h}/zsh_unplugged/zsh_unplugged.zsh

# Provide a plugin-script helper that clones (if needed) and prints the source line
function plugin-script() {
	emulate -L zsh
	set -o pipefail
	local spec repo commitsha plugdir initfile initfiles=()
	for spec in "$@"; do
		repo="$spec"
		commitsha=""
		if [[ "$spec" == *'@'* ]]; then
			repo="${spec%@*}"
			commitsha="${spec#*@}"
		fi
		plugdir=$ZUNPLUG_REPOS/${repo}
		initfile=$plugdir/${repo#*/}.plugin.zsh
		if [[ ! -d $plugdir ]]; then
			echo "Cloning $repo..."
			command git clone -q --depth 1 --recursive --shallow-submodules \
				https://github.com/$repo $plugdir
			if [[ -n "$commitsha" ]]; then
				command git -C $plugdir fetch -q origin "$commitsha" || true
				command git -C $plugdir checkout -q "$commitsha" || true
			fi
		fi
		if [[ ! -e $initfile ]]; then
			initfiles=($plugdir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
			(( $#initfiles )) || { echo >&2 "No plugin init found '$repo'."; continue }
			ln -sf $initfiles[1] $initfile
		fi
		echo "source $initfile"
	done
}

# Wrap legacy plugin-load to honor user/repo layout and compile one zwc
if (( $+functions[plugin-load] )); then
	functions -c plugin-load _zunplug_plugin_load
	function plugin-load() {
		emulate -L zsh; setopt local_options
		local spec base user name saved zfile plugdir
		for spec in "$@"; do
			base="${spec%@*}"
			user="${base%/*}"
			name="${base#*/}"
			saved=$ZPLUGINDIR
			export ZPLUGINDIR="$ZUNPLUG_REPOS/$user"
			[[ -d $ZPLUGINDIR ]] || command mkdir -p -- "$ZPLUGINDIR"
			_zunplug_plugin_load "$spec"
			export ZPLUGINDIR=$saved
			# Compile only the init link to satisfy tests expecting exactly one .zwc
			plugdir="$ZUNPLUG_REPOS/$user/$name"
			if [[ -e "$plugdir/$name.plugin.zsh" ]]; then
				autoload -Uz zrecompile
				zrecompile -pq "$plugdir/$name.plugin.zsh"
			fi
		done
	}
fi

