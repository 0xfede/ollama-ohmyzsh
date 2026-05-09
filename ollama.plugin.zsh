# ollama.plugin.zsh — Oh My Zsh plugin for Ollama.
# Registers the completion function and a couple of convenience aliases.

# Expose the completion directory to fpath so Oh My Zsh's compinit picks up _ollama.
0=${(%):-%x}
typeset -g _OLLAMA_PLUGIN_DIR=${0:A:h}
fpath=($_OLLAMA_PLUGIN_DIR $fpath)

# If compinit has already run (Oh My Zsh does this after loading plugins),
# explicitly load the completion so users don't need to open a new shell.
if (( $+functions[compdef] )); then
    autoload -Uz _ollama
    compdef _ollama ollama
fi

# Aliases
alias ol='ollama'
alias olr='ollama run'
alias olp='ollama pull'
alias olls='ollama list'
alias olps='ollama ps'
alias olrm='ollama rm'
alias olst='ollama stop'
