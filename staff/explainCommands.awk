#!/bin/awk -f
{
    if (/^#\? /) {
        printf "\033[34m▍\033[39m";
        for (i = 2; i <= NF; i++) {
            printf $i " ";
        }
        printf "\033[0m\n";
    } else if (/^function /) {
        if ($4 == "#x") next;
        command = "\033[34m" $2 "\033[2m ";
        while(length(command) < 29) {
            command = command "-";
        }
        printf("%s\033[0m", command);
        if ($4 == "#?") {
            printf "\033[36m ";
        } else if ($4 == "#!") {
            printf "\033[31m ";
        } else {
            printf " ";
        }
        for (i = 5; i <= NF; i++) {
            printf $i " ";
        }
        printf "\033[0m\n";
    } else if (/^alias /) {
        # gsub("'\''", "", $2);
        split($2, parts, "=");
        printf "\033[32malias \033[34m" parts[1] "\033[39m = \033[36m" parts[2];
        for (i = 3; i <= NF; i++) {
            # gsub("'\''", "", $i);
            printf(" %s", $i);
        }
        printf "\033[0m\n";
    } else if (/^forbidAlias /) {
        printf "\033[32malias \033[31m" $2 " \033[39m=>\033[34m";
        for (i = 3; i <= NF; i++) {
            printf(" %s", $i);
        }
        printf "\033[0m\n";
    }
}