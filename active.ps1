$CurrentLoc = $PSScriptRoot

$activation = ". $CurrentLoc\config.ps1"
If (-Not(Test-Path $profile)) {
	NI $profile -Force
}


$actived = $false
cat $profile | % {
	If ($_.Equals($activation)) {
		$actived = $true
		Break
	}
}	

If ($actived) {
	echo "Qfig had already been activated!"
} Else {
	$activation > $profile
	echo "Qfig activated"
}


clv activation 
clv actived
