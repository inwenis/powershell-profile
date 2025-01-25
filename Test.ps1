Import-Module Pester
Import-Module ./Profile.ps1

Describe 'Get-Planet' {
    It 'Given no parameters, it lists all 8 planets' {
        mkdir "test-git-repo"
        pushd "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1" # we need a commit so that master branch doesn't disappear after creating a new branch
        git checkout -b dummy-branch
        git commit --allow-empty -m "dummy commit 2"
        git checkout master
        git merge dummy-branch --no-ff --no-edit # no edit is needed to avoid editor opening

        Clear-Git-Branches

        $all = git branch --all
        $all | Should -Not -Contain "dummy-branch"
        popd
        Remove-Item "test-git-repo" -Recurse
    }
}