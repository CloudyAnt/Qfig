## The location of Qfig project
$_QFIG_LOC = $PSScriptRoot

## create local data folder
$_QFIG_LOCAL="$_QFIG_LOC\.local"
If (-Not (Test-Path -PathType Container -Path "$_QFIG_LOCAL")) {
	New-Item -ItemType Directory -Path "$_QFIG_LOCAL"
}

## Base configs
. $_QFIG_LOC\command\baseCommands.ps1

## Custom configs
$preferTextEditor = "NotePad"
If (-Not $IsWindows) {
	$preferTextEditor = "vim"
}

If (Test-Path -PathType Leaf $_QFIG_LOCAL\config) {
	$content = $(Get-Content "$_QFIG_LOCAL\config") -join "`n"
	$verbose = $($content -match '<showVerboseInitMsg>(.+)</showVerboseInitMsg>' -And "true".Equals($matches[1])) ? 1 : 0
	$enabledCommands = ""
	$enabledCommandsMap = @{}
	$sources = @()

	function Add-QSource() {
		param([Parameter(Mandatory)][string]$cmds)
		if ($cmds -match ".+:.+") {
			if ($cmds -match ".+:ps1") {
				# only load powershell commands
				$cmds = $cmds.Substring(0, $cmds.Length - 4)
			} else {
				return
			}
		}

		if ($enabledCommandsMap[$cmds] -eq 1) {
			return
		}
		$enabledCommandsMap[$cmds] = 1
		$cmds = $cmds.trim()
		$cmdsFile = "$_QFIG_LOC\command\${cmds}Commands.ps1"
		If (Test-Path -PathType Leaf "$cmdsFile") {

			Get-Content $cmdsFile | ForEach-Object {
				If ($_ -match "#requiring-end *") {
					return
				} ElseIf ($_ -match "^#require ([a-z]+)$") {
					Add-QSource $matches[1]
				}
			}

			$global:sources += $cmdsFile
			$global:enabledCommands += " $cmds"
		} ElseIf ($verbose) {
			logWarn "$cmdsFile Not Exists!"
		}
	}

	If ($content -match '<enabledCommands>([\s\S]*)</enabledCommands>') {
		$matches[1].Split("`n") | ForEach-Object {
			If ([string]::IsNullOrEmpty($_)) {
				Return
			} Else {
				Add-QSource $_
			}
		}
	}

	foreach ($sourceFile in $sources) {
		. $sourceFile
	}

	$initMsg = ""
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

	If ($content -match '<psTabStyle>(.+)</psTabStyle>') {
		If ("Windows".Equals($matches[1])) {
			Set-PSReadLineOption -EditMode Windows
			Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
			$initMsg += "Tab style: Windows. "
		} ElseIf ("Unix".Equals($matches[1])) {
			Set-PSReadLineOption -EditMode Emacs
			Set-PSReadLineKeyHandler -Key Tab -Function Complete
			$initMsg += "Tab style: Unix. "
		} Else {
			logWarn "Unsupported tab key action style: $(matches[1])"
		}
	}

	If ($verbose) {
		logInfo $initMsg
	}

	Clear-Variable sources
	Clear-Variable verbose
	Clear-Variable matches
	Clear-Variable content
	Clear-Variable enabledCommands
	Clear-Variable enabledCommandsMap
	Clear-Variable _preferTextEditor
	Remove-Item Function:Add-QSource
}

## Load functions that only works on current computer
If (Test-Path $_QFIG_LOC\command\localCommands.ps1) {
	. $_QFIG_LOC\command\localCommands.ps1
}
