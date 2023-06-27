#? These are commands about java, make sure it's available before use.

function JavaFileNameCompeletor() { #x
    param ($commandName, $parameterName, $wordToComplete)

    $originalOutputEncoding = [console]::OutputEncoding
    [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

    Get-ChildItem $wordToComplete*.java

    [console]::OutputEncoding = $originalOutputEncoding
}

function jrun() { #? java compile then run, jrun Hello => javac Hello.java && java Hello
    param(
        [Parameter(Mandatory)][ArgumentCompleter({ JavaFileNameCompeletor @args })]$file
    )

    $filenameParts = $file.split(".")
    If ($filenameParts.Length -Eq 2 -And $filenameParts[1].Equals("java")) {
    } Elseif ($filenameParts.Length -Eq 1) {
        $file = $file + ".java"
    }

    If (-Not(Test-Path $file)) {
        logError "File doesn't exist !"
        Return
    }

    javac $file

    # return if javac failed
    If (-Not($?)) {
        Return
    }

    java $filenameParts[0]
}