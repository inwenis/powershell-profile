$ErrorActionPreference = "stop"

function Git-Diff {
    param(
        [Parameter(Mandatory)][string]$fileA,
        [Parameter(Mandatory)][string]$fileB
    )

    $tempEmpty = $null
    try {
        $tempEmpty = New-TemporaryFile
        Set-Content -Path $tempEmpty -Value '' -NoNewline

        $pathA = if (Test-Path -LiteralPath $fileA) { $fileA } else { $tempEmpty }
        $pathB = if (Test-Path -LiteralPath $fileB) { $fileB } else { $tempEmpty }

        # --no-pager - if the diff is large we don't want pagination
        # --color - force color output even if the output is not a terminal
        # --no-index - one of the files is not in a git repository
        $diff = git --no-pager diff --color --no-index -- $pathA $pathB
        return $diff
    }
    finally {
        if ($tempEmpty -and (Test-Path -LiteralPath $tempEmpty)) {
            Remove-Item -LiteralPath $tempEmpty -Force -ErrorAction SilentlyContinue
        }
    }
}



function Deploy-File {
    param (
        [Parameter(ValueFromPipeline)] [System.IO.FileInfo] $file,
                                       [string]             $destinationDir
    )

    process {
        $fileIncoming = $file.FullName
        $fileDeployed = Join-Path $destinationDir $file.Name

        Write-Host "Deploying $($file.Name)..."
        $diff = Git-Diff $fileDeployed $fileIncoming
        $diff | Write-Host
        if ($null -eq $diff) {
            Write-Host "No changes in $($file.Name) to deploy"
        } else {
            Copy-Item -Path $fileIncoming -Destination $fileDeployed
            Write-Host "Done deploying $($file.Name)"
        }
    }
}

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4
$profileDir   = $PROFILE | Split-Path -Parent
$resourcesDir = "$profileDir\resources"

if (-not (Test-Path $profileDir)) {
    # The "PowerShell" directory might not exist, but it's the only directory in the path that might be missing
    New-Item -ItemType Directory -Path $profileDir | Out-Null
}
if (-not (Test-Path $resourcesDir)) {
    New-Item -ItemType Directory -Path $resourcesDir | Out-Null
}

Get-Item "./profile.ps1" | Deploy-File -DestinationDir $profileDir
Get-ChildItem -Path "./resources" -File | Deploy-File -DestinationDir $resourcesDir

Write-Host "Reloading profile in current session..."
# todo - can I use Reload-Profile from Profile.ps1 to reload the profile?
New-ModuleManifest .\temp.psd1  -NestedModules "./profile.ps1"
# '*> $null' is used because if reloading of the profile is done more than once in a session we get a strange error
# about `Remove-Item Function:Get-PoshStackCount` not being able to be removed but the profile is reloaded correctly
# we use $null here as Out-Null can not receive all streams
Import-Module ./temp -Global -Force *> $null
Remove-Item .\temp.psd1
Write-Host "Done"
