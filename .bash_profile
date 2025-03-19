if [ -f ~/.bash_profile_secrets ]; then
    source ~/.bash_profile_secrets
fi

alias cg="pushd /mnt/c/git"

# source bashrc since it's not sourced by default when .bash_profile exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
