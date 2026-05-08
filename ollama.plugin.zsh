# ollama plugin for Oh My Zsh  ⚡🦙
# Full version → https://github.com/0xfede/ollama-ohmyzsh

# ---------------------------------------------------------------
# OLLAMA_CONFIG (user-overridable)
# ---------------------------------------------------------------
: ${OLLAMA_MODEL_LIST_CMD:=ollama list}
: ${OLLAMA_API_URL:=http://localhost:11434}
: ${OLLAMA_RESTART_CMD:=launchctl kickstart -k user/$(id -u)/com.github.ollama.ollama}

# ---------------------------------------------------------------
# COMPINIT
# ---------------------------------------------------------------

autoload -Uz compinit _init_completion
compinit -d "$ZSH/.cache/zcompdump-${HOSTNAME:-localhost}" 2>/dev/null || true

# ---------------------------------------------------------------
# OLLAMA-OPTFUN helpers (used by completions)
# ---------------------------------------------------------------

_ollama_available_models() {
    # Return space-separated local model names from "ollama list".
    # Strips sha256 tags, keeps name[:tag].
    $OLLAMA_MODEL_LIST_CMD 2>/dev/null \
      | awk '{print $1}' \
      | grep -Eo '^[a-zA-Z0-9._/-]+(?=:sha256)' \
      || true
}

_ollama_running_models() {
    # Query the running API for currently loaded models.
    # Returns newline-separated list; empty string if unreachable.
    curl -sf "${OLLAMA_API_URL}/api/tags" 2>/dev/null \
      | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for m in data.get('models', []):
        print(m['name'])
except Exception:
    pass
" || true
}

_ollama_all_models() {
    # Union of local + running (deduplicated).
    local local_m running_m all=()
    read -rA local_m <<< "$(_ollama_available_models)"
    read -rA running_m <<< "$(_ollama_running_models)"
    declare -A seen
    for n in "${local_m[@]}"; do seen[$n]=1; done
    for n in "${running_m[@]}"; do seen[$n]=1; done
    echo -n "${(j: :)${(k)seen}}"
}

# ---------------------------------------------------------------
# OLLAMA COMPLETIONS
# ---------------------------------------------------------------

_ollama() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        -m|--modelfile)  curcontext="${curcontext}:ollama-modelfile:" && _files ;;
        --port|-p)       _values 'port' '(0)' '' ;;
        --ngl|-n)        _values 'gpu_layers' $(seq 1 999) ;;
    esac

    case $words[$cword] in
        run|stop|delete|rm|cp)
            local m; read -rA m <<< "$(_ollama_all_models)"
            _describe 'model' m
            return ;;
        show)
            if (( CURRENT == 2 )); then
                local m; read -rA m <<< "$(_ollama_all_models)"
                _describe 'model' m
            else
                _values 'flag' \
                    '--embeddings[Show embeddings]' \
                    '--verbose[Show model info in verbose mode]' \
                    '-m[--modelfile]:Modelfile:_files' \
                    '-p[--port][Port to run server on:]' ''
            fi
            return ;;
        push)
            local m; read -rA m <<< "$(_ollama_available_models)"
            _describe 'model to push' m
            return ;;
        create)  # autocomplete base model names for FROM directive
            local m; read -rA m <<< "$(_ollama_all_models)"
            _describe 'base model' m
            return ;;
        tags)
            local m; read -rA m <<< "$(_ollama_available_models)"
            _describe 'model to tag' m
            return ;;
        pull)    # No registry search in Ollama — user types full name.
            _wanted 'model-pattern' expl 'registry model pattern' compadd \
                -- $cur 2>/dev/null || true
            return ;;
        list|ls)
            if (( CURRENT == 2 )); then
                _values 'flag' '--all-tags[List all tags for each model]' ''
            fi
            return ;;
    esac

    # Top-level subcommands
    local -a commands=(
        'run[Run a model interactively]' \
        'stop[Stop a running model by name or "all"]' \
        'delete[Delete a model (same as rm)]' \
        'rm[Remove a model]' \
        'show[Show information about a model (use --flags for details)]' \
        'pull[Pull a model from the Ollama library]' \
        'push[Publish a model to a registry]' \
        'create[Create a model from a Modelfile]' \
        "cp[c]$'\n'[Copy a model]" \
        'tags[Tag a model as latest or versioned tag]' \
        'list[List models locally (same as ls)]' \
        'ls[List models locally (alias for list)]' \
        'serve[Start the Ollama server]' \
        'version[Show ollama version]' \
        'help[Help about any command]'
    )

    _describe 'command' commands 2>/dev/null || return $ret
}
compdef _ollama ollama

# ---------------------------------------------------------------
# CONVENIENCE ALIASES / FUNCTIONS
# ---------------------------------------------------------------

# Quick-run: `o [model]` → `ollama run [model]`
o() {
    command ollama run "${@:-}"
}

# Restart Ollama on macOS (launchctl reboot). `orc`
orc() {
    echo $'Ollama \x1b[33mrestarting\x1b[0m...' >&2
    eval "$OLLAMA_RESTART_CMD" 2>&1 || \
        echo "Try manually: launchctl kickstart -k ..." >&2
}

# List currently running models in a nice table. `ollama-running`
ollama_running() {
    local json
    json=$(curl -sf "${OLLAMA_API_URL}/api/tags" 2>/dev/null) || {
        echo "Ollama API unreachable at ${OLLAMA_API_URL}" >&2
        return 1
    }
    echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

models = data.get('models', [])
if not models:
    print('No running models')
    sys.exit(0)

print(f'%-60s %12s' % ('MODEL', 'SIZE BYTES'))
print('-' * 74)
for m in models:
    size = m.get('size', 0)
    info = (m.get('models_info') or [{}])[0]
    desc = ', '.join(info.get('descendant_names', [])) if info.get('descendant_names') else ''
    print(f'%-60s %12d' % (m['name'], size), end='')
    if desc:
        print(f'  models: {desc}')
    else:
        print()
"
}

# Show all locally available models. `ollama-all`
ollama_all() {
    command ollama list "$@" 2>/dev/null \
      | column -t -s '  '
}

# Show metadata about a specific model. `ollama-info <name>`
ollama_info() {
    local model="${1:?Usage: ollama-info <model-name>}"
    command ollama show --verbose "$model" 2>/dev/null | \
        awk '{print "🦙 Ollama info for:", $0}'
}

# Delete all locally pulled models (with confirmation). `ollama-rm-all`
ollama_rm_all() {
    echo -n '⚠️  This will delete ALL locally available models. Continue? [y/N] '
    read -r ans
    case "$ans" in
        [yY]|[yY][eE][sS])
            for name in "${(@f)$(_ollama_available_models)}"; do
                echo "  Removing $name..."
                command ollama rm "$name" >/dev/null 2>&1
            done
            echo 'Done.'
            ;;
        *) echo 'Cancelled.' >&2 ;;
    esac
}

# Aliases for quick use
alias ora='ollama_running'
alias allmods='ollama_all'
