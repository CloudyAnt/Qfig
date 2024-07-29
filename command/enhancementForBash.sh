# Enhancement for bash

function -() { cd -; } # use alias here is illegal
alias ~="cd $HOME" # go to home directory
alias ..="cd .." # go to upper level directory