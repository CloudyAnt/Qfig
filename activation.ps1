# Activate Qfig for powershell

$CurrentLoc = $PSScriptRoot

If (-Not(Test-Path $profile)) {
	NI $profile -Force
}


$activationSegment = ". $CurrentLoc/init.ps1"
$activated = $false
cat $profile | % {
	If ($_.Equals($activationSegment)) {
		$activated = $true
		Break
	}
}	

If ($activated) {
	echo "Qfig had already been activated!"
} Else {
	$activationSegment > $profile
	echo "Qfig has been activated! Open a new session to check."
}

clv activationSegment 
clv activated 
