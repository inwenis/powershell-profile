# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4
$profileDir  = "$HOME\Documents\PowerShell"
$profileFile = "$profileDir\Profile.ps1"
if (-not (Test-Path $profileDir)) {
    # The "PowerShell" might not exist, but it's the only directory in the path that might be missing
    New-Item -ItemType Directory -Path $profileDir
}
Copy-Item -Path "./profile.ps1" -Destination $profileFile
