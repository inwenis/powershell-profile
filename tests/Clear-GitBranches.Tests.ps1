Set-StrictMode -version latest
Import-Module Pester
Import-Module ./Profile.ps1 -Force

BeforeAll {
    # if somehow the folder is left from previous run, remove it
    if (Test-Path "executing-tests-here") {
        Remove-Item "executing-tests-here" -Recurse -Force
    }
    mkdir "executing-tests-here"
    Push-Location "executing-tests-here"
}

AfterAll {
    Pop-Location
    Remove-Item "executing-tests-here" -Recurse -Force
}

Describe 'Clear-GitRepo' {
    It 'Removes a local branch merged into master' {
        mkdir "test-git-repo"
        Push-Location "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1" # we need a commit so that master branch doesn't disappear after creating a new branch
        git checkout -b dummy-branch *> $null # https://stackoverflow.com/questions/57538714/suppress-output-from-git-command-in-powershell
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null
        git merge dummy-branch --no-ff --no-edit # no edit is needed to avoid editor opening

        $out = Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "dummy-branch"
        $out | ForEach-Object { $_ | Should -Not -BeLike "*fatal*" }
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
    }

    It 'Removes multiple local branches merged into master' {
        mkdir "test-git-repo"
        Push-Location "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git checkout -b dummy-branch-1 *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null
        git merge dummy-branch-1 --no-ff --no-edit
        git checkout -b dummy-branch-2 *> $null
        git commit --allow-empty -m "dummy commit 3"
        git checkout master *> $null
        git merge dummy-branch-2 --no-ff --no-edit

        Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "dummy-branch-1"
        $branches | Should -Not -Contain "dummy-branch-2"
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
    }

    It 'Removes remote branch merged into master' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git checkout -b dummy-branch *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null
        git merge dummy-branch --no-ff --no-edit
        Pop-Location

        git clone test-git-repo-remote "test-git-repo" *> $null
        Push-Location "test-git-repo"

        Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "remotes/origin/dummy-branch"
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

    It 'Removes multiple remote branch merged into master' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git checkout -b dummy-branch-1 *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null
        git merge dummy-branch-1 --no-ff --no-edit
        git checkout -b dummy-branch-2 *> $null
        git commit --allow-empty -m "dummy commit 3"
        git checkout master *> $null
        git merge dummy-branch-2 --no-ff --no-edit
        Pop-Location

        git clone test-git-repo-remote "test-git-repo" *> $null
        Push-Location "test-git-repo"

        Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "remotes/origin/dummy-branch-1"
        $branches | Should -Not -Contain "remotes/origin/dummy-branch-2"
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

    It 'Does not write errors if there are no branches to remove' {
        mkdir "test-git-repo"
        Push-Location "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1" # we need a commit so that master branch actually exists

        $out = Clear-GitRepo

        $out | ForEach-Object { $_ | Should -Not -BeLike "*fatal*" }
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
    }

#    It 'Does not write errors if there are no branches to remove and the repo is completely empty' {
#        mkdir "test-git-repo"
#        Push-Location "test-git-repo"
#        git init
#
#        $out = Clear-GitRepo
#
#        $out | ForEach-Object { $_ | Should -Not -BeLike "*fatal*" }
#        Pop-Location
#        Remove-Item "test-git-repo" -Recurse -Force
#    }

    It 'Removes remote refs gone from remote' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git checkout -b dummy-branch *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null # we need to leave master checked out so that cloning has master checked out by default
        Pop-Location

        git clone test-git-repo-remote "test-git-repo" *> $null

        Push-Location "test-git-repo-remote"
        git br -D dummy-branch
        Pop-Location

        Push-Location "test-git-repo"
        git pull
        Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "remotes/origin/dummy-branch"
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

    It 'Does not print an error if remote branch is already deleted' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git checkout -b dummy-branch *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null # we need to leave master checked out so that cloning has master checked out by default
        git merge dummy-branch --no-ff --no-edit *> $null
        Pop-Location

        git clone test-git-repo-remote "test-git-repo" *> $null

        Push-Location "test-git-repo-remote"
        git br -D dummy-branch
        Pop-Location

        Push-Location "test-git-repo"

        $out = Clear-GitRepo

        $out | ForEach-Object { $_ | Should -Not -BeLike "*error*" }
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

    It 'Works with main branch instead of master' {
        mkdir "test-git-repo"
        Push-Location "test-git-repo"
        git init --initial-branch=main
        git commit --allow-empty -m "dummy commit 1" # we need a commit so that master branch doesn't disappear after creating a new branch
        git checkout -b dummy-branch *> $null # https://stackoverflow.com/questions/57538714/suppress-output-from-git-command-in-powershell
        git commit --allow-empty -m "dummy commit 2"
        git checkout main *> $null
        git merge dummy-branch --no-ff --no-edit # no edit is needed to avoid editor opening

        $out = Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }
        $branches | Should -Not -Contain "dummy-branch"
        $out | ForEach-Object { $_ | Should -Not -BeLike "*fatal*" }
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
    }

    It 'Works with any HEAD branch in origin' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init --initial-branch=dummy-head-branch
        git commit --allow-empty -m "dummy commit 1"
        Pop-Location

        git clone test-git-repo-remote "test-git-repo" *> $null

        Push-Location "test-git-repo"
        git checkout -b dummy-branch *> $null
        git commit --allow-empty -m "dummy commit 2"
        git checkout dummy-head-branch *> $null
        git merge dummy-branch --no-ff --no-edit

        $out = Clear-GitRepo

        $branches = git branch --all | ForEach-Object { $_.Trim() }

        $branches | Should -Not -Contain "dummy-branch"
        $out | ForEach-Object { $_ | Should -Not -BeLike "*error*" }
        $out | ForEach-Object { $_ | Should -Not -BeLike "*fatal*" }
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

    It 'If both master and main are present local only, an error is thrown' {
        mkdir "test-git-repo"
        Push-Location "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git branch main *> $null

        { Clear-GitRepo } | Should -Throw -ExpectedMessage 'Both master and main branches are present locally. Remove one of them.'

        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
    }

    It 'Removes tags removed from remote' {
        mkdir "test-git-repo-remote"
        Push-Location "test-git-repo-remote"
        git init
        git commit --allow-empty -m "dummy commit 1"
        git tag dummy-tag-1
        Pop-Location

        git clone "test-git-repo-remote" "test-git-repo" *> $null

        Push-Location "test-git-repo-remote"
        git tag -d dummy-tag-1
        Pop-Location

        Push-Location "test-git-repo"
        Clear-GitRepo

        $tags = git tag

        $tags | Should -Not -Contain "dummy-tag-1"
        Pop-Location
        Remove-Item "test-git-repo" -Recurse -Force
        Remove-Item "test-git-repo-remote" -Recurse -Force
    }

}
