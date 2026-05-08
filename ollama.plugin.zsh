#ollama.plugin.zsh — Tab completion for ollama commands
# Compatible with Oh My Zsh · Uses native zsh completion, no external deps.

#compdef ollama

# --------------------------------------------------------------------------
# Configuration (user-overridable in ~/.zshrc before OMZ plugins block)
# --------------------------------------------------------------------------
: ${OLLAMA_MODEL_LIST_CMD:=ollama list}
: ${OLLAMA_API_URL:=http://localhost:11434}

# --------------------------------------------------------------------------
# Dynamic model resolvers → these feed _describe / compadd
# --------------------------------------------------------------------------

__ollama_local_models() {
    # Return model names from "ollama list", stripping :sha256… tags.
    $OLLAMA_MODEL_LIST_CMD 2>&1 | awk 'NR>1{sub(/:sha256.*/,"",$1); print $1}' | sort -u
}

__ollama_running_models() {
    # Return the names of models currently loaded in VRAM via /api/tags.
    curl -sf "$OLLAMA_API_URL/api/tags" 2>/dev/null | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for m in (data.get("models") or []):
    # "name" may be "<sha>", but we want it for stop; for display use
    # the base name if present.  Just echo "name" as-is — that is what
    # ollama stop expects.
    print(m.get("name", m.get("digest","")))' || true
}

__ollama_all_models() {
    # Union of local + running; deduplicated, preserving order.
    local -A seen
    while IFS= read -r m; do [ -n "$m" ] && seen[$m]=1; done \
        < <(__ollama_local_models)
    while IFS= read -r m; do [ -n "$m" ] && seen[$m]=1; done \
        < <(__ollama_running_models)
    print -rl -- ${(k)seen}
}

__ollama_stop_candidates() {
    # __complete for "ollama stop" — only models currently in VRAM, plus "all".
    local running
    running=$(__ollama_running_models)
    if [ -n "$running" ]; then
        print -rl -- ${(f)running} all
    else
        echo "all"
    fi
}

# --------------------------------------------------------------------------
# Completion function
# --------------------------------------------------------------------------
_ollama() {
    local cur

    # Get the word being completed (zsh 5+ style).
    cur=${words[CURRENT]}
    (( CURRENT == 1 )) && return

    # -- Flags that any subcommand may need.
    _arguments -s \
        '--modelfile[Use a Modelfile]:file:_files' \
        '-m[Use a Modelfile]:file:_files' \
        "--port[Bind address for server (integer in brackets)]:host:(localhost)" \
        '-p[Bind address for server (integer in brackets)]:host:(localhost)'

    # -- Top-level subcommands.
    case ${words[CURRENT-1]} in
        "")   # first argument after "ollama" — show available subcommands
            _describe -t 'command' 'ollama commands' \
                -J \
                run  "run:Run a model interactively" \
                stop "stop:Stop a running model (by name or \"all\")" \
                delete "delete:Delete a locally loaded model" \
                rm   "rm:Remove a locally loaded model" \
                show "show:Show information about a model" \
                pull "pull:Pull a model from the Ollama library" \
                push "push:Push a model to a registry" \
                create "create:Create a model from a Modelfile" \
                cp   "cp:Copy a model" \
                tags "tags:Tag a model as latest or versioned tag" \
                list "list:List models locally (alias for ls)" \
                ls   "ls:List models locally (alias for list)" \
                serve "serve:Start/Run the Ollama server" \
                version "version:Show ollama version" \
                help "help:Help about any command"
            ;;

        run) # ollama run <model> [--flag]
            if (( CURRENT == 3 )); then   # third word = model name
                _describe -t 'model' 'model to run' \
                    ($(__ollama_all_models)) "all:All locally loaded models" \
                    && return 0

                # Fallback: suggest any prefix match from local+running.
                local all_m=($(__ollama_all_models) all)
                _describe -t 'model' 'run-model' $all_m
            else   # flags like --embeddings, --verbose
                _describe -t 'flag' 'run flags' \
                    --embeddings "Show embeddings from prompt" \
                    --verbose "Verbose output"
            fi
            ;;

        stop)  # ollama stop <model|"all"> — VRAM models only.
            _describe -t 'running-model' "stop candidate" \
                ($(__ollama_stop_candidates))
            ;;

        delete|rm)  # ollama delete/rm <model> — local + running.
            _describe -t 'model' 'model-name' \
                ($(__ollama_all_models))
            ;;

        show)           # ollama show <model> [--flag]
            if (( CURRENT == 3 )); then   # third word = model name
                _describe -t 'model' 'model to inspect' \
                    ($(__ollama_all_models))
            else                          # flags.
                _describe -t 'flag' 'show flags' --embeddings "Show embeddings" --verbose "Verbose output"
            fi
            ;;

        pull)  # ollama pull <pattern> — user types full name; no smart registry list for Ollama.
            _files              # accept anything, no filter.
            ;;

        push)  # ollama push <local-model>: optional registry reference.
            local model=$(__ollama_all_models)
            _describe -t 'model' 'local model' $model
            (( CURRENT > 2 )) && return    # allow second-arg (registry/user/repo:tag).
            ;;

        create)         # ollama create <name> [-f file] — optional base model.
            if (( CURRENT == 4 )); then   # third word is FROM-model.
                _describe -t 'base-model' 'FROM base model' \
                    ($(__ollama_all_models))
            fi
            ;;

        cp)            # ollama cp <from> <to>.
            if (( CURRENT == 3 )); then
                _describe -t 'model' 'source model' \
                    ($(__ollama_all_models))
            elif (( CURRENT == 4 )); then   # allow any name (new copy).
                return 0    # no filter — new names can be anything syntactically.
            fi
            ;;

        tags)          # ollama tag <model> <tag>.
            if (( CURRENT == 3 )); then
                _describe -t 'model' 'model to tag' \
                    ($(__ollama_all_models))
            fi
            ;;

        list|ls)       # no args except --all-tags.
            case ${words[CURRENT]} in
                --*)
                    _values 'list flag' --all-tags "List all tags for each model"
                    ;;
            esac
            ;;

        serve)         # ollama serve [--flag].
            case ${words[CURRENT]} in
                --*)
                    _values 'serve flag' \
                        '--host[HTTP(S) bind address]' \
                        '--port[Server TCP port]'
                    ;;
            esac
            ;;

        version)   # nothing to complete.
            return 0
            ;;

        help)
            _describe -t 'command' "help target" \
                run stop delete rm show pull push create cp tags list ls serve version help
            ;;
    esac

    return 0
}

compdef _ollama ollama

# --------------------------------------------------------------------------
# Convenience helpers (load-only; do not clobber user aliases).
# --------------------------------------------------------------------------

o() { command ollama run "${@:-}" }   # Quick-run.

orc() {      # macOS: restart Ollama via launchd.
    if ! kill -0 $(( $(id -u) )) >/dev/null 2>&1; then
        echo "Cannot find user/$(id -u)/com.github.ollama.ollama" >&2
        return 1
    fi
    print -P '\e[33m🔄 Ollama restarting\e[0m' >&2
    launchctl kickstart -k \
        "user/$(id -u)/com.github.ollama.ollama" 2>&1 || true
}

ollama_running() {   # Nicely formatted list of loaded models.
    local json
    json=$(curl -sf "$OLLAMA_API_URL/api/tags" 2>/dev/null) || {
        print -r -- "Ollama API unreachable at $OLLAMA_API_URL" >&2
        return 1
    }
    echo "$json" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

models = data.get("models", [])
if not models:
    print("No running models")
    sys.exit(0)

print(f"%-56s %12s" % ("MODEL", "SIZE BYTES"))
print("-" * 70)
for m in models:
    size = m.get("size", 0)
    info = (m.get("models_info") or [{}])[0]
    desc = ", ".join(info.get("descendant_names", [])) if info.get("descendant_names") else ""
    print(f"%-56s %12d" % (m["name"], size), end="")
    if desc:
        print(f"  models: {desc}")
    else:
        print()
'
}

ollama_all() {       # All locally available models.
    command ollama list 2>/dev/null \
        | awk 'NR>1{sub(/:sha256.*/,"",$1); printf "%-56s %s\n",$1,$3}' 
    || print -r -- "(no models found)" >&2
}

ollama_info() {   # Metadata about a specific model.
    local model=${1:?Usage: ollama_info <model-name>}
    command ollama show --verbose "$model" 2>/dev/null | \
        awk '{print "🦙 Ollama info:", $0}'
}

ollama_rm_all() {   # Remove every locally pulled model.
    print -n -r -- '⚠️  This will delete ALL locally pulled models. Continue? [y/N] '
    local ans=""
    read -rs ans || true
    case "$ans" in
        [yY]|[yY][eE][sS])
            while IFS= read -r name; do
                print "  Removing $name..."
                command ollama rm "$name" >/dev/null 2>&1
            done < <(__ollama_local_models)
            ;;
        *) print -r -- "Cancelled." >&2 ;;
    esac
}

# Quick aliases (only if user hasn't defined them already).
alias ora='ollama_running'   || true
alias allmods='ollama_all'  || true
