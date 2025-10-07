# Legacy compatibility shim
# Loads the vendored zsh_unplugged implementation.
0=${(%):-%N}
source ${0:A:h}/zsh_unplugged/unplugged.zsh
