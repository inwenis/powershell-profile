# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4
$profileLocation = "$HOME\Documents\PowerShell\Profile.ps1"
Copy-Item -Path "./profile.ps1" -Destination $profileLocation
