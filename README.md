# Qfig

This's my libray of **shell/PowerShell** scripts and also customizable tool commands provider.

Activate Qfig by running the script **activation.sh/ps1** (run **activation-cygwin.sh** on cygwin).
**Note** that the PowerShell scripts are compatible with PowerShell 7+. shell scripts are compatible with zsh 5+ or bash 5+, others temporaily not supprted.

## Basic Support
- Commands in **baseCommands.sh/ps1** are always availabe. Run `qcmds base` to check.
- Run `qcmds -h` to check available commands(prefixes) and operations to those commands.
## Customization
- Run `qfig config` to configure extra enabled commands, prefer text editor, etc. 
- Run `qcmds local edit` to write only-in-this-device commands.

*Any new changes will be effective in new sessions. To make it effective immidiately by running command `resh` in shell or `. $profile` in powershell.*
