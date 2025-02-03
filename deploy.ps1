# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4
$profileDir  = "$HOME\Documents\PowerShell"
$profileFile = "$profileDir\Profile.ps1"
$resourcesDir = "$profileDir\resources"
$theOnlyResourcesFileSoFar = "settings.json"
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
Write-Host "Done"

Write-Host "Deploying resources..."
$diff = git --no-pager diff (Join-Path $resourcesDir $theOnlyResourcesFileSoFar) "./resources/$theOnlyResourcesFileSoFar"
git --no-pager diff (Join-Path $resourcesDir $theOnlyResourcesFileSoFar) "./resources/$theOnlyResourcesFileSoFar"
if ($null -eq $diff) {
    Write-Host "No changes to deploy"
}
Copy-Item -Path "./resources/$theOnlyResourcesFileSoFar" -Destination (Join-Path $resourcesDir $theOnlyResourcesFileSoFar)
Write-Host "Done"

New-ModuleManifest .\temp.psd1  -NestedModules "./Profile.ps1"

# Even with adding " -ErrorAction SilentlyContinue | Out-Null" Import module prints an error if deploy.ps1 is run twice
# However it seems to work as expect
Import-Module ./temp -Global -Force

Remove-Item .\temp.psd1
