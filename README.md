# ollama-ohmyzsh

An Oh My Zsh plugin providing **context-aware tab completion** for the
[Ollama](https://ollama.com) CLI, plus a few handy aliases.

## Features

Completion adapts to the subcommand you're typing:

| You type              | TAB completes with                                  |
|-----------------------|-----------------------------------------------------|
| `ollama <TAB>`        | All subcommands (`run`, `pull`, `ps`, `launch`, …)  |
| `ollama run <TAB>`    | Local models **and** the ollama.com library         |
| `ollama stop <TAB>`   | Only models currently loaded (from `ollama ps`)     |
| `ollama pull <TAB>`   | Models from the ollama.com library                  |
| `ollama pull foo:<TAB>` | Tags for `foo` scraped from ollama.com/library/foo |
| `ollama push <TAB>`   | Local model names                                   |
| `ollama show <TAB>`   | Local model names                                   |
| `ollama rm <TAB>`     | Local model names (multi-arg)                       |
| `ollama cp <TAB>`     | Local model names (source), then free name (dest)   |
| `ollama create <TAB>` | Free name, `-f` takes a Modelfile                   |
| `ollama launch <TAB>` | Known integrations (`claude`, `codex`, `vscode`, …) |
| `ollama help <TAB>`   | Help topics                                         |

Flags are completed too (`--verbose`, `--keepalive`, `--think`,
`--quantize`, `--insecure`, etc.).

Registry lookups are cached for 24 hours in
`~/.cache/ollama-ohmyzsh/`. Override with `OLLAMA_COMPLETION_CACHE_TTL`
(seconds).

## Aliases

| Alias  | Command        |
|--------|----------------|
| `ol`   | `ollama`       |
| `olr`  | `ollama run`   |
| `olp`  | `ollama pull`  |
| `olls` | `ollama list`  |
| `olps` | `ollama ps`    |
| `olrm` | `ollama rm`    |
| `olst` | `ollama stop`  |

## Installation

Clone into your Oh My Zsh custom plugins directory:

```bash
git clone https://github.com/0xfede/ollama-ohmyzsh.git \
    ~/.oh-my-zsh/custom/plugins/ollama
```

Then enable it in `~/.zshrc`:

```zsh
plugins=(... ollama)
```

Reload your shell:

```bash
exec zsh
```

## Requirements

- `zsh` + Oh My Zsh
- `ollama` (for local-model completions)
- `curl` (for registry completions)

The plugin honors `$OLLAMA_HOST` (defaults to `127.0.0.1:11434`).
