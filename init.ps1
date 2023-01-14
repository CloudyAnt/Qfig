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
If (Test-Path $Qfig_loc/config) {
	If((Get-Content $Qfig_loc/config) -join "`n" -match '<enabledCommands>([\s\S]*)</enabledCommands>') {
		$matches[1].Split("`n") | % {
			If ([string]::IsNullOrEmpty($_)) {
				Return
			} Else {
				$cmdsFile="$Qfig_loc/command/${_}Commands.ps1"	
				If (Test-Path "$cmdsFile") {
					. $cmdsFile
				} Else {
					logWarn "$cmdsFile Not Exists!"
				}
			}
		}
	}
	If((Get-Content $Qfig_loc/config) -join "`n" -match '<preferTextEditor>(.+)</preferTextEditor>') {
		If (-Not [string]::IsNullOrEmpty($matches[1])) {
			$preferTextEditor=$matches[1]
			logInfo "Using prefer text editor: $preferTextEditor"
		}
	}
}

## For complex functions only works for your current orgnization, add them to the tempCommands.ps1
## All functions in this file will not be included in git
If (Test-Path $Qfig_loc/command/tempCommands.ps1) {
	. $Qfig_loc/command/tempCommands.ps1
}
