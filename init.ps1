# You can add custom configs in the 'config' file 

## The location of Qfig project
$Qfig_loc = $PSScriptRoot

## Base configs
. $Qfig_loc/command/baseCommands.ps1

## Custom configs
If (Test-Path $Qfig_loc/config) {
	If(Get-Content $Qfig_loc/config -join "`n" -match '<activedCommands>([\s\S]*)</activedCommands>') {
		$matches[1].Split("`n") | % {
			If ([string]::IsNullOrEmpty($_)) {
				Continue
			} Else {
				cmdsFile="$Qfig_loc/command/$_Commands.ps1"	
				If (Test-Path $cmdsFile) {
					. $cmdsFile
				} else {
					logWarn "$cmdsFile Not Exists!"
				}
			}
		}
	}
}

## For complex functions only works for your current orgnization, add them to the tempCommands.ps1
## All functions in this file will not be included in git
If (Test-Path $Qfig_loc/command/tempCommands.ps1) {
	. $Qfig_loc/command/tempCommands.ps1
}
