# Enhancement for PowerShell

function Enable-AutoCd { #x Enter on a directory path cds into it
	Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
		param($key, $arg)

		$line = $null
		$cursor = $null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

		$path = $line.Trim()

		if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
			$escaped = $path.Replace("'", "''")

			[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
				0,
				$line.Length,
				"Set-Location -LiteralPath '$escaped'"
			)
		}

		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
	}
}
