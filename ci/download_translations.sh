current_branch=$(git symbolic-ref --short HEAD)
crowdin download --branch $current_branch
