current_branch=$(git symbolic-ref --short HEAD)
crowdin upload sources --branch $current_branch
