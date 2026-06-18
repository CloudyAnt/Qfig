# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Qfig is a cross-shell (bash 5+, zsh 5+, PowerShell 7+) library of tool commands that extends the terminal with productivity functions. Users activate it by sourcing `init.sh` or `init.ps1` from their shell profile.

## Global variables set by init.sh

When `init.sh` is sourced, these globals are available to all command files. **Do not redefine or unset them:**

| Variable | Description |
|---|---|
| `_QFIG_LOC` | Absolute path to the Qfig project root |
| `_CURRENT_SHELL` | Either `"zsh"` or `"bash"` — drives shell-specific branching |
| `_QFIG_LOCAL` | Path to `.local/` data directory |
| `_DEF_IFS` | Default IFS, restored via `rdIFS` |
| `_IS_BSD` | `"1"` if BSD grep (macOS), empty if GNU grep |
| `_TEMP` | Scratch variable used as function "return value" mechanism |
| `_PREFER_TEXT_EDITOR` | User's preferred text editor |
| `Qfig_log_prefix` | Log prefix char (default `●`) |

`$_QFIG_LOC` and `$_QFIG_LOCAL` are the PowerShell equivalents (set by `init.ps1`).

## Architecture

### Activation flow

1. User runs `activation.sh` (or `activation.ps1` / `activation-cygwin.sh`)
2. This appends `source <QFIG_LOC>/init.sh` to `~/.zshrc`, `~/.bashrc`, `~/.bash_profile` (or `. <QFIG_LOC>/init.ps1` to PowerShell profile)
3. Each new shell session sources `init.sh` → sources `baseCommands.sh` → reads `.local/config` → sources enabled command modules

### Command module pattern

Each domain has paired files: `command/<name>Commands.sh` and `command/<name>Commands.ps1`. Users enable them by listing the prefix (e.g., `git`) in the `<enabledCommands>` block of `.local/config`. Append `:sh` or `:ps1` to restrict to one shell (e.g., `docker:sh`).

**Function annotation convention:**
- `#?` — user-facing function (shown in `qcmds explain` output)
- `#x` — internal/private function (hidden from `qcmds explain`)
- `#!` — deprecated function

**Cross-module dependencies:** A command file that needs functions from another module calls `enable-qcmds <other>` (shell) or `Get-EnableQcmdsExpr <other> | Invoke-Expression` (PowerShell) at the top. This is idempotent — double-sourcing is prevented.

**Shell-specific branching:** Use `$_CURRENT_SHELL` to branch between zsh and bash for syntax differences (array handling, regex matching with `$match` vs `BASH_REMATCH`, `vared` vs `read -e`, etc.).

### Key framework functions (baseCommands.sh)

- `qfig` — self-update, config, version reporting
- `qcmds` — list/explain/read/edit command modules
- `qmap` — manage key-value mapping files stored in `.local/` (e.g., SSH shortcuts, PEM paths)
- `refresh-qfig` / `resh` — reload Qfig or the entire shell profile
- `logInfo`, `logError`, `logWarn`, `logSuccess`, `logSilence` — colored logging with `●` prefix
- `readTemp` — cross-shell input reading; result stored in `_TEMP`
- `editfile` — opens a file in `$_PREFER_TEXT_EDITOR`
- `confirm` / `confirmYn` — user confirmation prompts
- `toArray` / `toArrayVar` — split string into array
- `echoe` — cross-shell `echo -e` equivalent
- `rdIFS` — restore default IFS
- `getArrayBase` — returns 0 or 1 depending on `ksharrays` option
- `filei` — `file -i` with BSD/GNU flag handling

### Mapping files

`qmap` parses key-value files (`<name>MappingFile` in `.local/`) into associative arrays. Format: `key=value` per line, with optional `#?<char>` to change the separator. The result is a global associative array (e.g., `_SSH_MAPPING`, `_PEM_MAPPING`). Parsing uses `staff/readMapFile.awk`.

### Enhancement files

`baseCommands.sh` auto-sources enhancement files based on shell and OS:
- `enhancementForBash.sh` — shell aliases (`-`, `~`, `..`)
- `enhancementForZsh.sh` — `readWithPromptAndLimit` using `vared`/`zle`
- `enhancementForDarwin.sh` — macOS quarantine removal, brew service aliases
- `enhancementForCygwin.sh` — wraps `refresh-qfig` to re-run `dos2unix` on reload

### gct (Git Commit Template)

Interactive commit composer driven by `staff/resolveGctPattern.sh` and `.gctpattern`. Uses a pattern like `<name@regex:default> <#type@regex:default>: <#message@regex:default>` to prompt for each commit-message field with validation. Caches per repo/branch in `.local/`.

### Local overrides

`command/localCommands.sh` and `command/localCommands.ps1` are gitignored and sourced automatically at init. Users write device-specific commands here.

## Common development tasks

- **Add a new command**: Create `command/<name>Commands.sh` and optionally `command/<name>Commands.ps1`. Annotate user-facing functions with `#?` and internal helpers with `#x`. If the command depends on another module, call `enable-qcmds <other>` at the top (shell) or use `Get-EnableQcmdsExpr` (PowerShell).
- **Explain a command module**: `qcmds <prefix>` prints all `#?`-annotated functions and aliases.
- **Edit a command module**: `qcmds <prefix> edit` opens it in the preferred text editor.
- **Handle shell differences**: Branch on `$_CURRENT_SHELL` for zsh vs bash. Use `echoe` instead of `echo -e`. Use `readTemp` instead of raw `read`/`vared`. Use `getMatch` instead of `$match`/`$BASH_REMATCH` directly.
- **Log consistently**: Use `logInfo` (cyan), `logWarn` (yellow), `logError` (red), `logSuccess` (green), `logSilence` (dimmed). Never use raw `echo` for messages to the user.
- **Return values from functions**: Shell functions can't return strings — store results in `_TEMP` and document that the caller must read it. Use `echoe` only for direct stdout output.
- **Getting info about a file's encoding**: Use `filei` (cross-platform `file -i`), not `chr2ucp`/`chr2uni` which are for terminal strings only (see encodingCommands.sh#L3).
