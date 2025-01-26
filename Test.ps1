Import-Module Pester
Import-Module ./Profile.ps1 -Force

$rootLocation = Get-Location

BeforeAll {
    # if somehow the folder is left from previous run, remove it
    if (Test-Path "executing-tests-here") {
        Remove-Item "executing-tests-here" -Recurse -Force
    }
    mkdir "executing-tests-here"
    pushd "executing-tests-here"
}

AfterAll {
    Set-Location $rootLocation
    Remove-Item "executing-tests-here" -Recurse -Force
}

Describe 'Clear-Git-Branches' {
    It 'Removes a local branch merged into master' {
        mkdir "test-git-repo"
        pushd "test-git-repo"
        git init
        git commit --allow-empty -m "dummy commit 1" # we need a commit so that master branch doesn't disappear after creating a new branch
        git checkout -b dummy-branch *> $null # https://stackoverflow.com/questions/57538714/suppress-output-from-git-command-in-powershell
        git commit --allow-empty -m "dummy commit 2"
        git checkout master *> $null
        git merge dummy-branch --no-ff --no-edit # no edit is needed to avoid editor opening

        Clear-Git-Branches

        $all = git branch --all | ForEach-Object { $_.Trim() }
        $all | Should -Not -Contain "dummy-branch"
        popd
        Remove-Item "test-git-repo" -Recurse -Force
    }

    It 'Removes multiple local branches merged into master' {
        mkdir "test-git-repo"
        pushd "test-git-repo"
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

        Clear-Git-Branches

        $all = git branch --all | ForEach-Object { $_.Trim() }
        $all | Should -Not -Contain "dummy-branch-1"
        $all | Should -Not -Contain "dummy-branch-2"
        popd
        Remove-Item "test-git-repo" -Recurse -Force
    }
}