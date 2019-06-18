alias update='sudo apt-get update && sudo apt-get upgrade'

alias clip='xclip -sel c'
alias paste='xclip -sel c -o'

alias clipget="curl -s https://clipboard.antonchristensen.net 2>&1"
clipset() {
    if [ -z "$1" ]
    then
        _temp_cat=`cat`
        _std_in="$_temp_cat"
    else
        _std_in="$1"
    fi
    _std_in="clip=$_std_in"
    curl https://clipboard.antonchristensen.net --data-urlencode "$_std_in"
}

alias ppaste='paste | clipset'
alias cclip='clipget | clip'
