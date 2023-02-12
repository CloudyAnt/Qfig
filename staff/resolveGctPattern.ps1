param([Parameter(Mandatory)]$pattern)
# pattern='[name:]-[type:a b c]#[card:0 1]@@[message:Nothing]'

# token types:
# 0:
# 1:abc:d e f
[string[]]$tokens = @()
$escaping = 0

# x(status) types:
# 0 append string
# 1 append key
# 2 append option
$x = 0
$i = -1
$s = ""
$stepsCount = 0
Foreach($c In $pattern.toCharArray()) {
    $i += 1
    If (([char]'\').Equals($c)) {
        $escaping = 1
        Continue
    }
    If ($escaping) {
        $s = "$s$c"
        $escaping = 0
        Continue
    }

    Switch($x) {
        0 {
            If (([char]']').Equals($c)) {
                Write-Host "Bad ending '$c' at index $i"
                Exit 1
            } ElseIf (([char]'[').Equals($c)) {
                If ($s) {
                    $tokens += "0`:$s"
                    $s = ""
                }
                $x=1
            } Else {
                $s = "$s$c"
            }
        }
        1 {
            If (([char]':').Equals($c)) {
                If ($s) {
                    $k = $s
                    $s = ""
                    $x = 2
                } Else {
                    Write-Output "Bad options begining '$c' at index $i. Key name must not be empty"
                    Exit 1
                }
            } ElseIf (([char]'[').Equals($c)) {
                Write-Output "Bad key beiginning '$c' at index $i. Specifiying key `"$k`" content"
                Exit 1
            } ElseIf (([char]']').Equals($c)) {
                If ($s) {
                    $tokens += "1`:$s"
                    $stepsCount += 1
                    $s = ""
                    $x = 0
                } Else {
                    Write-Output "Bad key ending '$c' at index $i. Key name must not be empty"
                    Exit 1
                }
            } Else {
                $s = "$s$c"
            }
        }
        2 {
            If (([char]'[').Equals($c)) {
                Write-Output "Bad key beginning '$c at index $i. Specifying key `"$k`" options"
                Exit 1
            } ElseIf (([char]']').Equals($c)) {
                if ($s) {
                    $tokens += "1`:$k`:$s"
                    $stepsCount += 1
                } Else {
                    Write-Output "No options specified for key `"$k`""
                    Exit 1
                }
                $s = ""
                $x = 0
            } Else {
                $s = "$s$c"
            }
        }
    }
}

If ($x -Eq 0) {
    If ($s) {
        $tokens += "0`:$s"
    }
} ElseIf ($x -Eq 1 -Or $x -Eq 2) {
    Write-Output "Bad ending! Step specification not ended"
    Exit 1
}
If ($stepsCount -Eq 0) {
    Write-Output "No steps specified!"
    Exit 1
}

Return $tokens