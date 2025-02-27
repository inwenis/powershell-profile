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

Describe 'Set-LocationExe' {
    It 'Does nothing when no exe is found' {
        mkdir "test-dir"
        Push-Location "test-dir"

        $out = Set-LocationExe

        $out | Should -BeNullOrEmpty
        Pop-Location
        Remove-Item "test-dir" -Recurse -Force
    }
}
