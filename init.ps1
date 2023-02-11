# You can add custom configs in the 'config' file 

## The location of Qfig project
$Qfig_loc = $PSScriptRoot

## Base configs
. $Qfig_loc/command/baseCommands.ps1

## Custom configs
$preferTextEditor = "NotePad"
If (-Not $IsWindows) {
	$preferTextEditor = "vim"
}

If (Test-Path $Qfig_loc/config) {
	$content = $(Get-Content "$Qfig_loc/config") -join "`n"
	$verbose = $($content -match '<showVerboseInitMsg>(.+)</showVerboseInitMsg>' -And "true".Equals($matches[1])) ? 1 : 0
	$enabledCommands = ""
	If ($content -match '<enabledCommands>([\s\S]*)</enabledCommands>') {
		$matches[1].Split("`n") | % {
			If ([string]::IsNullOrEmpty($_)) {
				Return
			} Else {
				$cmds = $_.trim()
				$cmdsFile = "$Qfig_loc/command/${cmds}Commands.ps1"	
				If (Test-Path "$cmdsFile") {
					. $cmdsFile
					$enabledCommands += " $cmds"
				} Else {
					logWarn "$cmdsFile Not Exists!"
				}
			}
		}
	}
    If ($verbose) {
		$enabledCommands ? (logInfo "Enabled commands:$enabledCommands") : (logInfo "None Enabled commands")
	}

	$_preferTextEditor = ""
	If ($content -match '<preferTextEditor>(.+)</preferTextEditor>') {
		$_preferTextEditor = $matches[1].trim()
		If (-Not [string]::IsNullOrEmpty($_preferTextEditor)) {
			$preferTextEditor = $_preferTextEditor
		}
	}
	If ($verbose) {
		$_preferTextEditor ? (logInfo "Using prefer text editor: $preferTextEditor") : (logInfo "Using default text editor: $preferTextEditor")
	}
	
	Clear-Variable verbose
	Clear-Variable matches
	Clear-Variable enabledCommands 
	Clear-Variable _preferTextEditor
}

## For functions only works on current computer, add them to the tempCommands.sh/tempCommands.ps1. The file is ignored by git
If (Test-Path $Qfig_loc/command/tempCommands.ps1) {
	. $Qfig_loc/command/tempCommands.ps1
}
