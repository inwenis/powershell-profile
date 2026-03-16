if (Test-Path -Path "~/.gitconfig") {
    Remove-Item -Path "~/.gitconfig" -Force
}

git config --global user.name  $env:GIT_USER_NAME
git config --global user.email $env:GIT_USER_EMAIL

git config --global init.defaultBranch main

git config --global core.editor "code --wait"

git config --global alias.co   "checkout"
git config --global alias.cb   "checkout -b"
git config --global alias.br   "branch"
git config --global alias.st   "status"
git config --global alias.a    "add"
git config --global alias.aa   "add --all"
git config --global alias.c    "commit"
git config --global alias.cam  "!f() { git commit --all --message `"$*`"; }; f" # you don't have to wrap the message in "
git config --global alias.ca   "commit         --all"
git config --global alias.cm   "commit               --message"
git config --global alias.d    "commit --amend"
git config --global alias.dn   "commit --amend                 --no-edit"
git config --global alias.dan  "commit --amend --all           --no-edit"
git config --global alias.dm   "commit --amend       --message"
git config --global alias.dam  "commit --amend --all --message"
git config --global alias.df   "diff"
git config --global alias.dfs  "diff --staged"
git config --global alias.g    "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
git config --global alias.p    "push"
git config --global alias.pf   "push --force"
git config --global alias.aliases "!f() { git config --list | grep ^alias\\. | cut -c 7- | grep -Ei `"`$1`" | awk -F= '{key=`$1; val=substr(`$0,length(`$1)+2); keys[NR]=key; vals[NR]=val; if(length(key)>max) max=length(key)} END {for(i=1;i<=NR;i++) printf `"%-`"max`"s = %s\n`", keys[i], vals[i]}'; }; f"

# PR-style diff: what did HEAD change since it diverged from the upstream branch?
# Usage: git pr         (defaults to upstream of current branch)
#        git pr main    (compare against main)
git config --global alias.pr  '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git diff --merge-base "$base" HEAD; }; f'

# Same, but show only a summary (files changed + insertions/deletions)
git config --global alias.prs '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git diff --merge-base --stat "$base" HEAD; }; f'

# Same, but list just filenames (great for quick scan)
git config --global alias.prn '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git diff --merge-base --name-only "$base" HEAD; }; f'

# Log equivalent: commits on HEAD that aren't in base (like base..HEAD)
git config --global alias.prl '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git log --oneline --decorate "${base}..HEAD"; }; f'

# Divergence view: show commits unique to each side (symmetric difference)
# Usage: git diverge main
git config --global alias.diverge '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git log --left-right --graph --oneline --decorate "${base}...HEAD"; }; f'

# The actual merge base (fork point) between base and HEAD
git config --global alias.mb '!f(){ base="$1"; [ -z "$base" ] && base="@{upstream}"; git merge-base "$base" HEAD; }; f'

git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate "true" # use n and N to move between diff sections
git config --global merge.conflictstyle "zdiff3"

# with this you don't have to explicitly set an upstream branch when pushing for the first time
# git checkout -b some-branch
# git push -u origin some-branch -> this becomes just git push
git config --global push.autoSetupRemote "true"

# inspired by https://www.augustl.com/blog/2009/global_gitignores
git config --global core.excludesfile ~/.gitignore
New-GitIgnore Global/VisualStudioCode > ~/.gitignore
