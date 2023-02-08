# Qfig

This's my libray of ***zsh/PowerShell*** scripts and also customizable tool commands provider.

Run the script `activation.sh/ps1` to activate commands for zsh/PowerShell.

**Notes**
The PowerShell scripts are compatible with PowerShell 7+

**Theories**:
- `baseCommands.sh/ps1` is the basic commands, always available.
- `tempCommands.sh/ps1` will be loaded if it exists. it will be ignored by `.gitignore`.
- Other commands under `commands` folder can be enabled by adding it's prefix to `<enabledCommands>` label in `config`.
- Modifications on `tempCommands.sh/ps1` and `config` will be effective in new session, or make it effective immidiately by running command `rezsh` in zsh or `. $profile` in powershell.
