Import-Module Pester
Import-Module ./Profile.ps1 -Force

$rootLocation = Get-Location

BeforeAll {
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
}