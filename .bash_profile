if [ -f ~/.bash_profile_secrets ]; then
    source ~/.bash_profile_secrets
fi

# source .profile since it's not sourced by default when .bash_profile exists
# .profile will source .bashrc
if [ -f ~/.profile ]; then
    source ~/.profile
fi

# makes ESC key remove whole line
bind '"\e":kill-whole-line'

alias cg="pushd /mnt/c/git"
alias c="code ."
