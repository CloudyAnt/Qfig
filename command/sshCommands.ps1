#? Ssh related commands.
#? You need to edit the ssh mapping file by execute 'qmap ssh'. A ssh mapping like: a=user@111.222.333.444:555
#? You also need to edit the pem mapping file by execute 'qmap pem' if needed. A pem mapping like: a=/path/to/pem

$_SSH_MAPPING_FILE="$_QFIG_LOCAL\sshMappingFile"
$_PEM_MAPPING_FILE="$_QFIG_LOCAL\pemMappingFile"

If (-Not (Test-Path $_SSH_MAPPING_FILE -PathType Leaf)) {
    New-Item $_SSH_MAPPING_FILE
}
If (-Not (Test-Path $_PEM_MAPPING_FILE -PathType Leaf)) {
    New-Item $_PEM_MAPPING_FILE
}

$_SSH_MAPPING = @{}
Get-Content $_SSH_MAPPING_FILE | ForEach-Object {
    $parts = $_.Split("=")
    $_SSH_MAPPING.Add($parts[0], $parts[1])
}

$_PEM_MAPPING = @{}
Get-Content $_PEM_MAPPING_FILE | ForEach-Object {
    $parts = $_.Split("=") 
    $_PEM_MAPPING.Add($parts[0], $parts[1])
}

function cs() {
    param([Parameter(Mandatory)]$key, $cmd)
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    ssh "ssh://$_SshEndpoint" $cmd
}

function csi() { #? connect server (or send command) with pem. Usage: csi mapping; csi mapping 'your remote command'
param([Parameter(Mandatory)]$key, $cmd)
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile=$_PEM_MAPPING["$key"]
    ssh -i $_PemFile "ssh://$_SshEndpoint" $cmd
}