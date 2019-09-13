alias clip='xclip -sel c'
alias paste='xclip -sel c -o'

alias backupClipboard="paste | xclip -sel backup"
alias restoreClipboard="xclip -sel backup -out | clip"

alias clipget="curl -s https://clipboard.antonchristensen.net 2>&1"
clipset() {
    cat /dev/stdin > /tmp/clipboardUpload
    curl -F 'paste=@/tmp/clipboardUpload' https://clipboard.antonchristensen.net/
}
alias ppaste='paste | clipset'
alias cclip='clipget | clip'

