---
name: ollama-ohmyzsh
description: Oh My Zsh plugin for Ollama with tab completion and handy aliases.
version: 0.1.0
---

# ollama-ohmyzsh ⚡🦙

An **Oh My Zsh plugin** for [Ollama](https://ollama.com) providing tab completion, model-status helpers, and quick-run aliases.

## Features

- **Full tab completion** for every Ollama subcommand (run, stop, pull, delete, push, create, cp, tags, rm all accept model names).
- **Dual model resolution** — completes from `ollama list` output **and** from the running API (`/api/tags`), so `ollama stop <TAB>` works even for models not on disk but currently loaded in VRAM.
- **Quick-run helpers**:
  - `o [model]` → `ollama run [model]`
  - `orc` → restarts the Ollama service (via launchd) and opens it.
- **Status helpers**:
  - `ollama-running` → shows all currently running models with resource usage.
  - `ollama-info <model>` → shows model metadata.
  - `ollama-all` → lists every locally available model with size/tag info.
- **Batch operations**:
  - `ollama-rm-all` → removes every locally pulled model (with confirmation).

## Installation

### Via Antigen
```zsh
antigen bundle 0xfede/ollama-ohmyzsh
```

### Via Oh My Zsh (manual, custom plugin)

1. Clone this repo into your custom plugins dir:
   ```bash
   mkdir -p ~/.oh-my-zsh/custom/plugins
   git clone https://github.com/0xfede/ollama-ohmyzsh.git \
       ~/.oh-my-zsh/custom/plugins/ollama
   ```

2. Add `ollama` to your plugins list in `~/.zshrc`:
   ```zsh
   plugins=(... ollama)
   ```

3. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

### Via zinit
```zsh
zinit load 0xfede/ollama-ohmyzsh
```

## Usage

After installation, all completions take effect immediately. Convenience functions are also available:

| Command          | What it does                        |
|------------------|-------------------------------------|
| `o [model]`      | Quick `ollama run [model]`           |
| `orc`            | Restart Ollama (launchctl reboot)   |
| `ollama-running` | Show currently loaded models + usage |
| `ollama-info X`  | Show model metadata                  |
| `ollama-all`     | List every locally available model   |
| `ollama-rm-all`  | Delete all local models (prompt)    |

## Completion Reference

| Command               | Completions for `<model>`           |
|-----------------------|-------------------------------------|
| `ollama run <TAB>`    | All local + running models          |
| `ollama stop <TAB>`   | Only **running** models             |
| `ollama delete <TAB>` | All local + running models          |
| `ollama rm <TAB>`     | All local + running models          |
| `ollama pull <TAB>`   | Registry suggestions (via `ollama search`) |
| `ollama push <TAB>`   | Local model names                   |
| `ollama cp <TAB>`     | All local + running models          |
| `ollama create <TAB>` | Existing model names as base        |
| `ollama show <TAB>`   | Flags: `--embeddings` `--verbose` … |

## Credits

Inspired by the [official Ollama Zsh completion](https://github.com/ollama/ollama/blob/main/integration/zsh/_ollama). Extended for Oh My Zsh with convenience wrappers and interactive helpers.
