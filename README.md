# Qfig

This's my library of **shell/PowerShell** scripts and also customizable tool commands provider.

Activate Qfig by running the script **activation.sh/ps1** (run **activation-cygwin.sh** on cygwin).
**Note** that the PowerShell scripts are compatible with PowerShell 7+. shell scripts are compatible with zsh 5+ or bash 5+, others temporarily not supported.

## Basic Support
- Commands in **baseCommands.sh/ps1** are always availabe. Run `qcmds base` to check.
- Run `qcmds -h` to check available commands(prefixes) and operations to those commands.
## Customization
- Run `qfig config` to configure extra enabled commands, prefer text editor, etc. 
- Run `qcmds local edit` to write only-in-this-device commands.

*Any new changes will be effective in new sessions. To make it effective immidiately by running command `qfig refresh` or `refresh-qfig` in shell, `. $profile` in powershell.*

## HighLight Functions
- **gct**: Interactive commit composer with configurable pattern, caching per repo/branch, options and regex validation. Check [gitCommands.sh:gct](./command/gitCommands.sh#L602-L861) for more details.
- **cs**: Connect to a server by saved config instead of typing full command. Check [sshCommands.sh:cs](./command/sshCommands.sh#L24-L30) for more details.
- **chr2ucp**: Convert characters to Unicode code points. Check [encodingCommands.sh:chr2ucp](./command/encodingCommands.sh#L98-L108) for more details.
- **rebase**: Convert an integer from one base to another. Check [mathCommands.sh:rebase](./command/mathCommands.sh#L77-L138) for more details.
- **rgb**: Tell you everything about a RGB color. Check [colorCommands.sh:rgb](./command/colorCommands.sh#L3-L83) for more details.
