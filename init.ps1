# You can add custom configs in the 'config' file 

## The location of Qfig project
$Qfig_loc = $PSScriptRoot

## Base configs
. $Qfig_loc/command/baseCommands.ps1

## Custom configs
$preferTextEditor="NotePad"
If (-Not $IsWindows) {
	$preferTextEditor="vim"
}
$verbose = ((Get-Content $Qfig_loc/config) -join "`n" -match '<showVerboseInitMsg>(.+)</showVerboseInitMsg>' -And "true".Equals($matches[1])) ? 1 : 0
If (Test-Path $Qfig_loc/config) {
	If((Get-Content $Qfig_loc/config) -join "`n" -match '<enabledCommands>([\s\S]*)</enabledCommands>') {
		$matches[1].Split("`n") | % {
			If ([string]::IsNullOrEmpty($_)) {
				Return
			} Else {
				$cmds = $_.trim()
				$cmdsFile = "$Qfig_loc/command/${cmds}Commands.ps1"	
				If (Test-Path "$cmdsFile") {
					. $cmdsFile
					If ($verbose) {
						logInfo "Enabled commands: $cmds"
					}
				} Else {
					logWarn "$cmdsFile Not Exists!"
				}
			}
		}
	}
	If((Get-Content $Qfig_loc/config) -join "`n" -match '<preferTextEditor>(.+)</preferTextEditor>') {
		$_preferTextEditor=$matches[1].trim()
		If (-Not [string]::IsNullOrEmpty($_preferTextEditor)) {
			$preferTextEditor=$_preferTextEditor
			if ($verbose) {
				logInfo "Using prefer text editor: $preferTextEditor"
			}
		}
	}
}

## For complex functions only works for your current orgnization, add them to the tempCommands.ps1
## All functions in this file will not be included in git
If (Test-Path $Qfig_loc/command/tempCommands.ps1) {
	. $Qfig_loc/command/tempCommands.ps1
}

## Unset temp variables
Clear-Variable cmds
Clear-Variable cmdsFile
Clear-Variable matches
Clear-Variable _preferTextEditor