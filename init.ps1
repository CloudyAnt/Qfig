## The location of Qfig project
$_QFIG_LOC = $PSScriptRoot

## create local data folder
if ($IsWindows) {
	$_QFIG_LOCAL="$_QFIG_LOC\.local"
} else {
	$_QFIG_LOCAL="$_QFIG_LOC/.local"
}
If (-Not (Test-Path -PathType Container -Path "$_QFIG_LOCAL")) {
	New-Item -ItemType Directory -Path "$_QFIG_LOCAL"
}

## Base configs
. $_QFIG_LOC\command\baseCommands.ps1

## Custom configs
$_PREFER_TEXT_EDITOR = "NotePad"
If (-Not $IsWindows) {
	$_PREFER_TEXT_EDITOR = "vim"
}

$localConfigFile="$_QFIG_LOCAL/config"
If (-Not (Test-Path -PathType Leaf $localConfigFile)) {
	$localConfigFile="$_QFIG_LOC/configTemplate"
}

If (Test-Path -PathType Leaf $localConfigFile) {
	$content = $(Get-Content "$localConfigFile") -join "`n"
	If ($content.Contains('<enabledCommands>')) {
		If (confirm "Legacy XML-style config detected. Convert it to INI format now?") {
			$convertedContent = $content `
				-replace '(?m)^[ \t]*<enabledCommands>[ \t]*$', '[enabledCommands]' `
				-replace '(?m)^[ \t]*</enabledCommands>[ \t]*\r?\n?', '' `
				-replace '<preferTextEditor>(.*)</preferTextEditor>', 'preferTextEditor=$1' `
				-replace '<showVerboseInitMsg>(.*)</showVerboseInitMsg>', 'showVerboseInitMsg=$1' `
				-replace '<psTabStyle>(.*)</psTabStyle>', 'psTabStyle=$1'
			Try {
				Copy-Item -Path $localConfigFile -Destination "$localConfigFile.bak" -Force -ErrorAction Stop
				Set-Content -Path $localConfigFile -Value $convertedContent -ErrorAction Stop
				$content = $convertedContent
				logSuccess "Converted $localConfigFile to INI format (backup: $localConfigFile.bak)."
			} Catch {
				logError "Failed to convert $localConfigFile to INI format: $_"
			}
		} Else {
			logWarn "Legacy config was not converted."
		}
	}
	$verbose = $($content -match '(?m)^showVerboseInitMsg=(.+)' -And "true".Equals($matches[1].trim())) ? 1 : 0
	$enabledCommands = ""
	$enabledCommandsMap = @{}

	# Add Line 'Get-EnableQcmdsExpr foo | Invoke-Expression' in the commands file if it requires foo commands
	function Get-EnableQcmdsExpr() {
		param([Parameter(Mandatory)][string]$cmds)
		if ($cmds -match ".+:.+") {
			if ($cmds -match ".+:ps1") {
				# only load powershell commands
				$cmds = $cmds.Substring(0, $cmds.Length - 4)
			} else {
				return " "
			}
		}
		$cmds = $cmds.trim()
		if ($enabledCommandsMap[$cmds] -eq 1) {
			return " "
		}
		$enabledCommandsMap[$cmds] = 1
		$cmdsFile = "$_QFIG_LOC\command\${cmds}Commands.ps1"
		If (Test-Path -PathType Leaf "$cmdsFile") {
			$global:enabledCommands += " $cmds"
			return ". $cmdsFile"
		} ElseIf ($verbose) {
			logWarn "$cmdsFile Not Exists!"
		}
		return " "
	}

	If ($content -match '\[enabledCommands\]([\s\S]*?)(\n\[|$)') {
		$matches[1].Split("`n") | ForEach-Object {
			$line = $_.trim()
			If ([string]::IsNullOrEmpty($line) -Or $line.StartsWith("#") -Or $line.Contains("=")) {
				Return
			} Else {
				Get-EnableQcmdsExpr $line | Invoke-Expression
			}
		}
	}

	$initMsg = ""
	If ($enabledCommands) {
		$initMsg += "Enabled commands:$enabledCommands. "
	} Else {
		$initMsg += "None Enabled commands. "
	}

	$preferTextEditor = ""
	If ($content -match '(?m)^preferTextEditor=(.+)') {
		$preferTextEditor = $matches[1].trim()

		If (-Not [string]::IsNullOrEmpty($preferTextEditor)) {
			$_PREFER_TEXT_EDITOR = $preferTextEditor
		}
	}

	If ($preferTextEditor) {
		$initMsg += "Text editor: $_PREFER_TEXT_EDITOR. "
	} Else {
		$initMsg += "Text editor: $_PREFER_TEXT_EDITOR(default). "
	}

	If ($content -match '(?m)^psTabStyle=(.+)') {
		If ("Windows".Equals($matches[1].trim())) {
			Set-PSReadLineOption -EditMode Windows
			Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
			$initMsg += "Tab style: Windows. "
		} ElseIf ("Unix".Equals($matches[1].trim())) {
			Set-PSReadLineOption -EditMode Emacs
			Set-PSReadLineKeyHandler -Key Tab -Function Complete
			$initMsg += "Tab style: Unix. "
		} Else {
			logWarn "Unsupported tab key action style: $($matches[1])"
		}
	}

	If ($verbose) {
		logInfo $initMsg
	}

	Clear-Variable verbose
	Clear-Variable matches
	Clear-Variable content
	Clear-Variable enabledCommands
	Clear-Variable enabledCommandsMap
	Clear-Variable preferTextEditor
	Remove-Item Function:Get-EnableQcmdsExpr
}

## Load functions that only works on current computer
If (Test-Path $_QFIG_LOC\command\localCommands.ps1) {
	. $_QFIG_LOC\command\localCommands.ps1
}
