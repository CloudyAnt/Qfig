# Make sure you are using Windows os! Else if you are using unix-like os, please use activation.sh

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
