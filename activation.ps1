# Activate Qfig for powershell(core 6+)

$CurrentLoc = $PSScriptRoot

If (-Not(Test-Path $profile)) {
	NI $profile -Force
}


# Check registration
$activationSegment = ". $CurrentLoc/init.ps1"
$activated = $false
Get-Content $profile | % {
	If ($_.Equals($activationSegment)) {
		$activated = $true
		Return
	}
}	

If ($activated) {
	Write-Host "Qfig had already been activated!"
} Else {
	$activationSegment >> $profile
	Write-Host "Qfig has been activated! Open a new session to check."
}

# Delete old registration
$oldSegment = "\. $CurrentLoc/config.ps1"
Set-Content -Path $profile -Value (Get-Content -Path $profile | Select-String -Pattern "$oldSegment" -SimpleMatch -NotMatch)

clv activationSegment 
clv activated 
