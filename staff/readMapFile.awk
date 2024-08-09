BEGIN { S = "unsetVar _TEMP;declare -gA _TEMP; _TEMP=("; SP = "="; BADLINES = "local badlines=\"" } # SP = separator
{
    if (/^#\?(.+)$/) {
        # change separator
        SP = substr($0, 3)
        next
    }

    if (/^#/) {
        # comment
        next
    }
    # find first separator index and split key and value
    firstSpIdx = index($0, SP)
    if (firstSpIdx == 0) {
        BADLINES = BADLINES NR " "
        next
    }

    key = substr($0, 1, firstSpIdx - 1)
    value = substr($0, firstSpIdx + 1)
    S = S " [" key "]=" value;
}
END { S = S ");"; BADLINES = BADLINES "\""; print S; print BADLINES }