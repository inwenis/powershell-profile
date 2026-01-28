$ErrorActionPreference = "stop"

function Git-Diff {
    param (
        [string] $fileA,
        [string] $fileB
    )

    # if the file doesn't exist we use NUL which is Window's equivalent of /dev/null
    # NUL is a special file that discards all data written to it, and returns EOF on read
    # https://ss64.com/nt/nul.html
    $fileA = if (Test-Path $fileA) { $fileA } else { "NUL" }
    $fileB = if (Test-Path $fileB) { $fileB } else { "NUL" }
    # --no-pager - if the diff is large we don't want pagination
    # --color - force color output even if the output is not a terminal
    # --no-index - one of the files is not in a git repository
    $diff = git --no-pager diff --color --no-index $fileA $fileB
    return $diff
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
# '*> Out-Null' is used because if reloading of the profile is done more than once in a session we get a strange error
# about `Remove-Item Function:Get-PoshStackCount` not being able to be removed but the profile is reloaded correctly
Import-Module ./temp -Global -Force *> NUL
Remove-Item .\temp.psd1
Write-Host "Done"
