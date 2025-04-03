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
$profileDir   = "$HOME\Documents\PowerShell"
$profileFile  = "$profileDir\Profile.ps1"
$resourcesDir = "$profileDir\resources"

if (-not (Test-Path $profileDir)) {
    # The "PowerShell" directory might not exist, but it's the only directory in the path that might be missing
    New-Item -ItemType Directory -Path $profileDir | Out-Null
}
if (-not (Test-Path $resourcesDir)) {
    # The "PowerShell" directory might not exist, but it's the only directory in the path that might be missing
    New-Item -ItemType Directory -Path $resourcesDir | Out-Null
}

Write-Host "Deploying profile..."
# run diff twice to capture the output and preserve colours when writing output to the console
$diff = git --no-pager diff $profileFile "./Profile.ps1"
git --no-pager diff $profileFile "./Profile.ps1"
if ($null -eq $diff) {
    Write-Host "No changes to deploy"
}
Copy-Item -Path "./Profile.ps1" -Destination $profileFile
Write-Host "Done deploying Profile.ps1"

Write-Host "Deploying resources..."
Get-ChildItem -Path "./resources" -File | Deploy-File -destinationDir $resourcesDir

# todo - can I use Reload-Profile from Profile.ps1 to reload the profile?
New-ModuleManifest .\temp.psd1  -NestedModules "./Profile.ps1"
# Even with adding " -ErrorAction SilentlyContinue | Out-Null" Import module prints an error if deploy.ps1 is run twice
# However it seems to work as expect
Import-Module ./temp -Global -Force
Remove-Item .\temp.psd1
