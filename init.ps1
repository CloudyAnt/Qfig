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
	$initMsg = ""
	If ($content -match '<enabledCommands>([\s\S]*)</enabledCommands>') {
		$matches[1].Split("`n") | ForEach-Object {
			If ([string]::IsNullOrEmpty($_)) {
				Return
			} Else {
				$cmds = $_.trim()
				$cmdsFile = "$Qfig_loc/command/${cmds}Commands.ps1"	
				If (Test-Path "$cmdsFile") {
					. $cmdsFile
					$enabledCommands += " $cmds"
				} ElseIf ($verbose) {
					logWarn "$cmdsFile Not Exists!"
				}
			}
		}
	}

	If ($enabledCommands) {
		$initMsg += "Enabled commands:$enabledCommands. "
	} Else {
		$initMsg += "None Enabled commands. "
	}

	$_preferTextEditor = ""
	If ($content -match '<preferTextEditor>(.+)</preferTextEditor>') {
		$_preferTextEditor = $matches[1].trim()
		If (-Not [string]::IsNullOrEmpty($_preferTextEditor)) {
			$preferTextEditor = $_preferTextEditor
		}
	}

	If ($_preferTextEditor) {
		$initMsg += "Text editor: $preferTextEditor. "
	} Else {
		$initMsg += "Text editor: $preferTextEditor(default). "
	}

	If ($verbose) {
		logInfo $initMsg
	}
	Clear-Variable verbose
	Clear-Variable matches
	Clear-Variable enabledCommands 
	Clear-Variable _preferTextEditor
}

## Load functions that only works on current computer
If (Test-Path $Qfig_loc/command/localCommands.ps1) {
	. $Qfig_loc/command/localCommands.ps1
}
