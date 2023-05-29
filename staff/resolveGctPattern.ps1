param([Parameter(Mandatory)]$pattern)
# pattern example:<name@^[^\:]+$:Unknown> <#type@^[^\:]+$:refactor fix feat chore doc test style>: <#message@^[^\:]+$:Unknown>

# token types:
# 0 String
# 1 Step
# 10 Branch-scope-step mark
# 11 Step regex
# 12 Step options
[string[]]$tokens = @()
$escaping = 0

# x(status) types:
# 0 append string
# 1 append key
# 2 append option
# 3 append regex
$x = 0
$i = -1 # index
$s = "" # current appended string
$stepsCount = 0
$stepRegex = ""
$lastStepKey = ""
$recordingStepType = $false
Foreach($c In $pattern.toCharArray()) {
    $i += 1

    if ($recordingStepType) {
        $recordingStepType = $false
        if (([char]'#').Equals($c)) {
            $tokens += "10`:"
            Continue
        }  
    }
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
            If (([char]'>').Equals($c)) {
                Write-Host "Bad ending '$c' at index $i"
                Exit 1
            } ElseIf (([char]'<').Equals($c)) {
                If ($s) {
                    $tokens += "0`:$s"
                    $s = ""
                }
                $x = 1
                $stepRegex = ""
                $recordingStepType = $true
            } Else {
                $s = "$s$c"
            }
        }
        1 { # appending key
            If (([char]':').Equals($c)) {
                If ($s) {
                    $tokens += "1`:$s"
                    $lastStepKey = $s
                    $s = ""
                    $x = 2
                } Else {
                    Write-Output "Bad options begining '$c' at index $i. Key name must not be empty"
                    Exit 1
                }
            } ElseIf (([char]'@').Equals($c)) {
                If ($s) {
                    $tokens += "1`:$s"
                    $s = ""
                    $x = 3
                } Else {
                    Write-Output "Bad regex begining '$c' at index $i. Key name must not be empty"
                    Exit 1
                }
            } ElseIf (([char]'<').Equals($c)) {
                Write-Output "Bad key beiginning '$c' at index $i. Specifiying key `"$lastStepKey`" content"
                Exit 1
            } ElseIf (([char]'>').Equals($c)) {
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
        2 { # appending options
            If (([char]'<').Equals($c)) {
                Write-Output "Bad key beginning '$c' at index $i. Specifying key `"$lastStepKey`" options"
                Exit 1
            } ElseIf (([char]'>').Equals($c)) {
                If ($s) {
                    If ($stepRegex) {
                        $ops = $s.Split(" ")
                        Foreach($option In $ops) {
                            If (-Not ($option -match $stepRegex)) {
                                Write-Output "Option `e[1m$option`e[0m is not matching `e[3m$stepRegex`e[0m"
                                Exit 1
                            }
                        }
                    }   
                    $tokens += "12`:$s"
                    $stepsCount += 1
                } Else {
                    Write-Output "Please specify options for key `"$lastStepKey`" or remove the ':'"
                    Exit 1
                }
                $s = ""
                $x = 0
            } Else {
                $s = "$s$c"
            }
        }
        3 { # appending regex
            If (([char]'<').Equals($c)) {
                Write-Output "Bad key beginning '$c' at index $i. Specifying key `"$lastStepKey`" options"
                Exit 1
            } ElseIf (([char]'>').Equals($c)) {
                if ($s) {
                    $tokens += "11`:$s"
                    $stepsCount += 1
                } Else {
                    Write-Output "No options specified for key `"$lastStepKey`""
                    Exit 1
                }
                $s = ""
                $x = 0
            } ElseIf (([char]':').Equals($c)) {
                If ("$s") {
                    $tokens += "11`:$s"
                    $stepRegex = $s
                    $s = ""
                    $x = 2
                } Else {
                    Write-Output "Please specify regex for key \"$lastStepKey\" or remove the '@'"
                    Exit 1
                }
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
    Write-Output "Bad ending! Step specification not ended. (status $x)"
    Exit 1
}
If ($stepsCount -Eq 0) {
    Write-Output "Please specify any steps!"
    Exit 1
}

Return $tokens
