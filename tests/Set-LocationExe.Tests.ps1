Set-StrictMode -version latest
Import-Module Pester
Import-Module $PSScriptRoot/../Profile.ps1 -Force

$wd = Get-Location

BeforeAll {
    # if somehow the folder is left from previous run, remove it
    if (Test-Path "executing-tests-here") {
        Remove-Item "executing-tests-here" -Recurse -Force
    }
    mkdir "executing-tests-here"
    Push-Location "executing-tests-here"
}

function Clear-LocationStack {
    $loc = Get-Location -Stack
    while ($loc.Count -gt 0) {
        $loc = Get-Location -Stack
        # tests might leave non-existing locations in the stack so if Pop-Location errors we ignore it
        Pop-Location -ErrorAction SilentlyContinue
    }
}

AfterAll {
    Clear-LocationStack
    Set-Location $wd
    Remove-Item "executing-tests-here" -Recurse -Force
}

Describe 'Set-LocationExe' {
    It 'Does nothing when no exe is found' {
        $out = Set-LocationExe

        $out | Should -BeNullOrEmpty
    }

    It 'If a single exe is found, it changes the location' {
        $wd = Get-Location
        mkdir "test-dir"
        New-Item "./test-dir/dummy.exe" -ItemType File

        Set-LocationExe

        Get-Location | Should -BeLike "*test-dir"
        Set-Location $wd
        Remove-Item "test-dir" -Recurse -Force
    }

    It 'Does not change location to non-exe files' {
        $wd = Get-Location
        mkdir "test-dir"
        New-Item "./test-dir/dummy.dum" -ItemType File

        Set-LocationExe

        Get-Location | Should -Not -BeLike "*test-dir"
        Set-Location $wd
        Remove-Item "test-dir" -Recurse -Force
    }

    It 'If there are multiple exes goes to the one selected by the user' {
        $wd = Get-Location
        mkdir "test-dir"
        New-Item "./test-dir/dummy.exe" -ItemType File
        mkdir "test-dir-go-here"
        New-Item "./test-dir-go-here/dummy.exe" -ItemType File

        # pipeline mocking needs to happen like this https://github.com/pester/Pester/issues/2154#issuecomment-2569173571
        Mock -CommandName Out-ConsoleGridView -MockWith { } -ParameterFilter { $InputObject.DirectoryName -notlike "*test-dir-go-here*" }
        Mock -CommandName Out-ConsoleGridView -MockWith { Get-Item "./test-dir-go-here/dummy.exe" } -ParameterFilter { $InputObject.DirectoryName -like "*test-dir-go-here*" }

        Set-LocationExe

        Get-Location | Should -BeLike "*test-dir-go-here"
        Set-Location $wd
        Remove-Item "test-dir-go-here" -Recurse -Force
        Remove-Item "test-dir" -Recurse -Force
    }

    It 'If Esc is pressed in Out-ConsoleGridView, it does not change location' {
        $wd = Get-Location
        mkdir "test-dir"
        New-Item "./test-dir/dummy.exe" -ItemType File
        mkdir "test-dir-go-here"
        New-Item "./test-dir-go-here/dummy.exe" -ItemType File

        Mock -CommandName Out-ConsoleGridView -MockWith { }

        Set-LocationExe

        Get-Location | Should -BeLike $wd
        Set-Location $wd
        Remove-Item "test-dir-go-here" -Recurse -Force
        Remove-Item "test-dir" -Recurse -Force
    }
}
