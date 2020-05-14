function gadd() {
    git add -A
}

function gct() {
    defaultV default_commit_name chaijiaqi
    defaultV default_commit_number N/A 
    defaultV default_commit_desc Unknown

    echo "What's your name? ($default_commit_name)"
    read commit_name
    echo "What's your card number? ($default_commit_number)"
    read commit_number
    echo "What did you do? ($default_commit_desc)"
    read commit_desc

    defaultV commit_name $default_commit_name
    defaultV commit_number $default_commit_number
    defaultV commit_desc $default_commit_desc

    default_commit_name=$commit_name
    default_commit_number=$commit_number
    default_commit_desc=$commit_desc

    commit_message="$commit_name [$commit_number] $commit_desc"

    git commit -m "$commit_message"
    
    unset commit_name
    unset commit_number
    unset commit_desc
    unset commit_message
}