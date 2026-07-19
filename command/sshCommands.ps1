#? Ssh related commands.
#? You need to edit the ssh mapping file by execute 'qmap ssh'. A ssh mapping like: a=user@111.222.333.444:555
#? You also need to edit the pem mapping file by execute 'qmap pem' if needed. A pem mapping like: a=/path/to/pem
#? Use csjump to jump, the ssh mapping should be like: a=jump_user@server_user@server_ip@jump_ip:jump_port

$_SSH_MAPPING_FILE = "$_QFIG_LOCAL\sshMappingFile"
$_PEM_MAPPING_FILE = "$_QFIG_LOCAL\pemMappingFile"

If (-Not (Test-Path $_SSH_MAPPING_FILE -PathType Leaf)) {
    New-Item $_SSH_MAPPING_FILE | Out-Null
}
If (-Not (Test-Path $_PEM_MAPPING_FILE -PathType Leaf)) {
    New-Item $_PEM_MAPPING_FILE | Out-Null
}

$_SSH_MAPPING = @{}
Get-Content $_SSH_MAPPING_FILE | ForEach-Object {
    If ([string]::IsNullOrWhiteSpace($_) -Or $_.StartsWith("#")) { Return }
    $parts = $_.Split("=", 2)
    If ($parts.Length -eq 2) {
        $_SSH_MAPPING[$parts[0]] = $parts[1]
    }
}

$_PEM_MAPPING = @{}
Get-Content $_PEM_MAPPING_FILE | ForEach-Object {
    If ([string]::IsNullOrWhiteSpace($_) -Or $_.StartsWith("#")) { Return }
    $parts = $_.Split("=", 2)
    If ($parts.Length -eq 2) {
        $_PEM_MAPPING[$parts[0]] = $parts[1]
    }
}

function Test-SshMapping { #x
    param([Parameter(Mandatory)]$key, [switch]$checkPem)
    If ([string]::IsNullOrWhiteSpace($key)) {
        logError "Please specify the ssh mapping key!"
        Return $false
    }
    If (-Not $_SSH_MAPPING.ContainsKey($key)) {
        logWarn "No ssh mapping for: $key. Use 'qmap ssh' to add."
        Return $false
    }
    If ($checkPem -And -Not $_PEM_MAPPING.ContainsKey($key)) {
        logWarn "No pem mapping for: $key. Use 'qmap pem' to add."
        Return $false
    }
    Return $true
}

function cs() { #? connect server. Usage: cs mapping; cs mapping 'your remote command'
    param([Parameter(Mandatory)]$key, $cmd)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    ssh "ssh://$_SshEndpoint" $cmd
}

function csc() { #? connect server & send command. Usage: csc mapping 'your remote command'
    param([Parameter(Mandatory)]$key, [Parameter(Mandatory)]$cmd)
    If (-Not (Test-SshMapping $key)) { Return }
    If ([string]::IsNullOrWhiteSpace($cmd)) {
        logWarn "Need command"
        Return
    }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    ssh "ssh://$_SshEndpoint" $cmd
}

function csi() { #? connect server (or send command) with pem. Usage: csi mapping; csi mapping 'your remote command'
    param([Parameter(Mandatory)]$key, $cmd)
    If (-Not (Test-SshMapping $key -checkPem)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile = $_PEM_MAPPING["$key"]
    ssh -i $_PemFile "ssh://$_SshEndpoint" $cmd
}

function cpt() { #? copy to server. Usage: cpt localFile mapping remoteFile[optional] pem[optional]
    param([Parameter(Mandatory)]$localFile, [Parameter(Mandatory)]$key, $remoteFile, $pem)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]

    If ([string]::IsNullOrWhiteSpace($remoteFile)) {
        logInfo "Coping file to remote user home as name `e[1m$localFile`e[0m"
        $remoteFile = $localFile
    }
    If ([string]::IsNullOrWhiteSpace($pem)) {
        scp $localFile "${_SshEndpoint}:$remoteFile"
    } Else {
        If (-Not (Test-Path $pem -PathType Leaf)) {
            logError "Specified pem file $pem doesn't exists!"
            Return
        }
        scp -i $pem $localFile "${_SshEndpoint}:$remoteFile"
    }
}

function cpti() { #? copy to server with pem. Usage: cpti localFile mapping remoteFile
    param([Parameter(Mandatory)]$localFile, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$remoteFile)
    If (-Not (Test-SshMapping $key -checkPem)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile = $_PEM_MAPPING["$key"]

    logInfo "Transferring $localFile to ${_SshEndpoint}:$remoteFile"
    scp -i $_PemFile $localFile "${_SshEndpoint}:$remoteFile"
}

function cprt() { #? recursively copy entire directories to server. Usage: cprt dir mapping remoteDir pem[optional]
    param([Parameter(Mandatory)]$localDir, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$remoteDir, $pem)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]

    If ([string]::IsNullOrWhiteSpace($pem)) {
        scp -r $localDir "${_SshEndpoint}:$remoteDir"
    } Else {
        If (-Not (Test-Path $pem -PathType Leaf)) {
            logError "Specified pem file $pem doesn't exists!"
            Return
        }
        scp -r -i $pem $localDir "${_SshEndpoint}:$remoteDir"
    }
}

function cpf() { #? copy from server. Usage: cpf remoteFile mapping localFile pem[optional]
    param([Parameter(Mandatory)]$remoteFile, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$localFile, $pem)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]

    If ([string]::IsNullOrWhiteSpace($pem)) {
        scp "${_SshEndpoint}:$remoteFile" $localFile
    } Else {
        If (-Not (Test-Path $pem -PathType Leaf)) {
            logError "Specified pem file $pem doesn't exists!"
            Return
        }
        scp -i $pem "${_SshEndpoint}:$remoteFile" $localFile
    }
}

function cpfi() { #? copy from server with pem. Usage: cpfi remoteFile mapping localFile
    param([Parameter(Mandatory)]$remoteFile, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$localFile)
    If (-Not (Test-SshMapping $key -checkPem)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile = $_PEM_MAPPING["$key"]

    scp -i $_PemFile "${_SshEndpoint}:$remoteFile" $localFile
}

function cprf() { #? copy folder from sever. Usage: cprf remoteDir mapping localDir pem[optional]
    param([Parameter(Mandatory)]$remoteDir, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$localDir, $pem)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]

    If ([string]::IsNullOrWhiteSpace($pem)) {
        scp -r "${_SshEndpoint}:$remoteDir" $localDir
    } Else {
        If (-Not (Test-Path $pem -PathType Leaf)) {
            logError "Specified pem file $pem doesn't exists!"
            Return
        }
        scp -r -i $pem "${_SshEndpoint}:$remoteDir" $localDir
    }
}

function cprfi() { #? copy folder from sever. Usage: cprfi remoteDir mapping localDir
    param([Parameter(Mandatory)]$remoteDir, [Parameter(Mandatory)]$key, [Parameter(Mandatory)]$localDir)
    If (-Not (Test-SshMapping $key -checkPem)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile = $_PEM_MAPPING["$key"]

    scp -r -i $_PemFile "${_SshEndpoint}:$remoteDir" $localDir
}

function sshcopyid() { #? copy ssh id to server
    param([Parameter(Mandatory)]$key)
    If (-Not (Test-SshMapping $key)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]

    If (Get-Command ssh-copy-id -ErrorAction SilentlyContinue) {
        ssh-copy-id $_SshEndpoint
        Return
    }

    $pubKey = $null
    Foreach ($candidate in @(
        "$env:USERPROFILE\.ssh\id_ed25519.pub",
        "$env:USERPROFILE\.ssh\id_rsa.pub",
        "$env:USERPROFILE\.ssh\id_ecdsa.pub"
    )) {
        If (Test-Path $candidate -PathType Leaf) {
            $pubKey = $candidate
            Break
        }
    }
    If (-Not $pubKey) {
        logError "No public key found under $env:USERPROFILE\.ssh"
        Return
    }
    Get-Content $pubKey | ssh $_SshEndpoint "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
}

function csjump() { #? connect server through a jump server
    param([Parameter(Mandatory)]$key)
    If (-Not (Test-SshMapping $key -checkPem)) { Return }
    $_SshEndpoint = $_SSH_MAPPING["$key"]
    $_PemFile = $_PEM_MAPPING["$key"]

    If ($_SshEndpoint -match '^[\w-]+@[\w-]+@[\w.-]+@[\w.-]+$') {
        ssh -i $_PemFile $_SshEndpoint
    } ElseIf ($_SshEndpoint -match '^[\w-]+@[\w-]+@[\w.-]+@[\w.-]+:(\d+)$') {
        $port = $Matches[1]
        ssh -p $port -i $_PemFile ($_SshEndpoint.Substring(0, $_SshEndpoint.LastIndexOf(':')))
    } Else {
        logError "Invalid ssh mapping !"
    }
}
