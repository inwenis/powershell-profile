# https://github.com/dahlbyk/posh-git?tab=readme-ov-file#step-2-import-posh-git-from-your-powershell-profile
Import-Module posh-git
# https://gist.github.com/tig/cbbeab7f53efd73e329afd6d4b838191
Import-Module -Name "F7History"

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.5
Set-StrictMode -version latest

# https://stackoverflow.com/a/52485269/2377787
# Store previous command's output in $__
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

$env:Path += ";c:\programki\"

$env:DOTNET_ENVIRONMENT = "Development"

# you can put a Secrets.ps1 file next to the profile on your machine to keep your secrets there
if (Test-Path "$PSScriptRoot/Secrets.ps1") {
    Write-Host "Loading secrets..."
    . "$PSScriptRoot/Secrets.ps1"
}

function Set-LocationGit { Set-Location "c:\git" }

function Set-LocationUp { Set-Location ".." }

function Set-LocationExe {
    $exe = @( Get-ChildItem -Filter "*.exe" -Recurse -File )
    $goto = $null

    if ($exe.Length -eq 1) {
        $goto = $exe[0].DirectoryName
    }
    else {
        # I don't know how to write a test ensuring that DirectoryName is displayed in Out-ConsoleGridView - it is not tested
        $selected =
            $exe
            | Select-Object -Property Mode, LastWriteTime, Length, DirectoryName, Name
            | Sort-Object LastWriteTime -Descending
            | Out-ConsoleGridView -Title "Where are we going?" -OutputMode Single
        if ($null -ne $selected) {
            $goto = $selected.DirectoryName
        }
    }

    if ($null -ne $goto) {
        Push-Location $goto
    }
}

function Invoke-Bfg { java -jar C:/programki/bfg-1.15.0.jar $args }

function Open-VsCodeDot { code . }

function Open-TotalCommander {
    # https://www.ghisler.ch/wiki/index.php/Command_line_parameters
    if ($args.Length -eq 0) {
        $wd = Get-Location
        . "C:\Program Files\totalcmd\TOTALCMD64.EXE" $wd /O /T
    }
    elseif ($args.Length -eq 1) {
        $path = Resolve-Path $args[0]
        . "C:\Program Files\totalcmd\TOTALCMD64.EXE" $path /O /T
    }
    else {
        Write-Host "Too many arguments. Provide a single path to open in Total Commander. Received: '$args'"
    }
}

function Start-Fiddler() {
    # to make fiddler work with NODE I needed to:
    # - trust root cert for HTTP
    # - enable TLS1.2 in protocols for HTTPS
    $env:HTTP_PROXY = "http://127.0.0.1:8888"
    $env:HTTPS_PROXY = "http://127.0.0.1:8888"
    $env:NODE_TLS_REJECT_UNAUTHORIZED = 0
    Start-Process "c:/Users/fku/AppData/Local/Programs/Fiddler/Fiddler.exe"
    Write-Output "tip - you can filter requests you see in fiddler by using Rules/User-Agents and set it to axios"
    Write-Output "you can also find the Windows proxy settings and disable the proxy that fiddler set. This way you should only see request from your console."
    Write-Output "Remember that intercepting requests will not work for scrapers that use certificates and a custom agent"
}

function Reset-Fiddler() {
    Remove-Item Env:\HTTP_PROXY
    Remove-Item Env:\HTTPS_PROXY
    Remove-Item Env:\NODE_TLS_REJECT_UNAUTHORIZED
    # to-do remove windows system proxy here (remove = unset/disable)
}

function Get-HeadBranch() {
    $private:remotes = git remote
    $private:headBranch = ""
    if ($remotes -Contains "origin") {
        $match = @(git remote show origin) | Select-String -Pattern "(?:HEAD branch:\s)(.*)"
        $headBranch = $match.Matches[0].Groups[1].Value
    } else {
        $headBranch = @(git branch --all --format="%(refname:short)") | Where-Object { $_ -eq "master" -or $_ -eq "main" }
        if ($headBranch -is [array]) {
            throw "Both master and main branches are present locally. Remove one of them."
        }
    }
    $headBranch
}

# todo - maybe add confirmation before actually deleting stuff
# this function will also delete local tags that are not present on the remote
function Clear-GitRepo() {
    # only `origin` is currently supported as remote
    # only `master` and `main` are currently supported as head branches

    $private:remotes = git remote
    if ($remotes -Contains "origin") {
        git fetch --prune --prune-tags origin
    }

    $headBranch = Get-HeadBranch

    $allBranches =
        git branch --all --merged $headBranch
        | Where-Object { ! ($_ -like "*$headBranch*") }
        | ForEach-Object { $_.Trim() }
    $localBranchesMergedIntoMaster  = @($allBranches | Where-Object { ! ($_ -like "*remotes/origin*") })
    $remoteBranchesMergedIntoMaster = @($allBranches | Where-Object {    $_ -like "*remotes/origin/*" } | ForEach-Object { $_.Replace("remotes/origin/", "refs/heads/") })
    if ($localBranchesMergedIntoMaster.Length -gt 0) {
        git branch -d $localBranchesMergedIntoMaster *>&1 | Write-Output
    } else {
        Write-Output "No local branches to clean."
    }
    if ($remoteBranchesMergedIntoMaster.Length -gt 0) {
        git push origin --delete $remoteBranchesMergedIntoMaster *>&1 | Write-Output
    } else {
        Write-Output "No remote branches to clean."
    }
}

function Get-GitStaleBranches($daysThreshold = 100) {
    function Get-GitHubCommitUrl($remoteUrl, $sha1) {
        "$remoteUrl/commit/$sha1"
    }

    git remote prune origin

    $now = [dateTimeOffset]::Now

    $headBranch = Get-HeadBranch
    $originUrl = git remote get-url origin

    $allBranches = git branch --all --format="'%(authorname)' '%(authoremail)' '%(committerdate:iso-strict)' '%(refname)' '%(objectname:short)'"
    $allBranches
    | ForEach-Object {
        $groups        = [regex]::match($_,"'(.*)' '<(.*)>' '(.*)' '(.*)' '(.*)'").Groups
        $date          = [DateTimeOffset]::Parse($groups[3].Value)
        $branch        = $groups[4].Value.Replace("refs/remotes/origin/", "").Replace("refs/heads/", "")
        $remoteOrLocal = if ($groups[4].Value -like "refs/remotes/origin/*") { "remote" } else { "local" }
        $age           = $now - $date

        [PSCustomObject]@{
            Author        = $groups[1].Value
            Email         = $groups[2].Value
            Date          = $date
            Branch        = $branch
            FullRef       = $groups[4].Value
            RemoteOrLocal = $remoteOrLocal
            Age           = $age
            SHA1          = $groups[5].Value
            Last          = [int] $age.TotalDays
    } }
    | Where-Object { $_.Branch -ne "$headBranch" }   # exclude master/main
    | Where-Object { $_.Branch -ne "HEAD" }          # exclude HEAD refs
    | Where-Object { $_.Age.TotalDays -gt $daysThreshold }
    | Sort-Object Date -Descending
    | ForEach-Object {
        $commitCount                = git log $headBranch..$($_.FullRef) --oneline | Measure-Object | Select-Object -ExpandProperty Count
        $dateFormatted              = $_.Date.ToString("yyyy-MM-dd HH:mm")
        $text                       = "Last commit by $($_.Author) ($($_.Email)) on $dateFormatted ($([int] $_.Age.TotalDays) days ago)"
        $branchNameAndRemoteOrLocal = "$($_.Branch) ($($_.RemoteOrLocal))"
        [PSCustomObject]@{
            Branch  = $branchNameAndRemoteOrLocal
            Text    = $text
            Last    = Get-GitHubCommitUrl $originUrl $_.SHA1
            Commits = $commitCount
        }
    }
}

function Clear-GitBranchesStale($daysThreshold = 100) {
    $stale = @(Get-GitStaleBranches $daysThreshold)

    if ($stale.Length -eq 0) {
        Write-Output "No stale branches found."
        return;
    }

    $selected = $stale | Out-ConsoleGridView

    foreach ($branch in $selected) {
        $branchName, $remoteOrLocal = $branch.Branch.Split(" ")
        if ($remoteOrLocal -eq "(remote)") {
            git push origin --delete $branchName
        } else {
            git branch -D $branchName
        }
    }
}

function Set-NodeExtraCaCertsForDCRepos() {
    $dcRepos = @("c:\git\IT.DataCapture", "c:\git\IT.ContinuousDataCapture")
    $currentDir = Get-Location
    $areWeInADcRepo = $dcRepos.Where({ $_ -eq $currentDir }).Count -gt 0
    if ($areWeInADcRepo) {
        $env:NODE_EXTRA_CA_CERTS = "./extraCerts.pem"
    }
    else {
        Remove-Item Env:\NODE_EXTRA_CA_CERTS
    }
}

function play() {

    # list from https://en.wikipedia.org/wiki/Video_file_format
    $videoExtensions = @(
        '*.yuv',
        '*.wmv',
        '*.webm',
        '*.vob',
        '*.viv',
        '*.svi',
        '*.roq',
        '*.rmvb',
        '*.rm',
        '*.ogv', '*.ogg',
        '*.nsv',
        '*.mxf',
        '*.MTS', '*.M2TS', '*.TS',
        '*.mpg', '*.mpeg', '*.m2v',
        '*.mpg', '*.mp2', '*.mpeg', '*.mpe', '*.mpv',
        '*.mp4', '*.m4p (with DRM)', '*.m4v',
        '*.mov', '*.qt',
        '*.mng',
        '*.mkv',
        '*.m4v',
        '*.gifv',
        '*.flv *.f4v *.f4p *.f4a *.f4b',
        '*.flv',
        '*.flv',
        '*.drc',
        '*.avi',
        '*.asf',
        '*.amv',
        '*.3gp',
        '*.3g2'
    )

    function Save-ToPlaylist($video) {
        $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $video.Name + ", " + $now | Out-File "play.txt" -Append
    }

    $videoToPlay = $null
    $videos      = @(Get-ChildItem "./*" -Include $videoExtensions | Sort-Object Name)
    $anyVideos   = $videos.Length -gt 0
    $playExists  = Test-Path "play.txt"

    if ($anyVideos -eq $true -and $playExists -eq $true) {
        $alreadyPlayedVideos = Get-Content -Path "play.txt" | ForEach-Object { $_.Split(",")[0] }
        $videoToPlay = $videos | Where-Object { $alreadyPlayedVideos -NotContains $_.Name } | Select-Object -First 1
        if ($null -eq $videoToPlay) {
            Write-Output "All videos played. Nothing more to play :("
        }
    } elseif ($anyVideos -eq $true -and $playExists -eq $false) {
        Write-Output "play.txt not found. Playing first video in directory."
        $videoToPlay = $videos | Select-Object -First 1
    }
    elseif ($anyVideos -eq $false ) {
        Write-Output "No videos here :("
    }

    if ($null -ne $videoToPlay) {
        Write-Output "Playing " $videoToPlay.Name
        Save-ToPlaylist $videoToPlay
        Invoke-Item -LiteralPath $videoToPlay.FullName
    }
}

function playground() {
    if (-not (Test-Path "C:/temp")) {
        New-Item -ItemType Directory -Path "C:/temp" | Out-Null
    }
    $existingDirs = Get-ChildItem "C:/temp"
    $latestDir = $existingDirs | Sort-Object Name -Descending | Select-Object -First 1
    $newDir = ""
    if ($null -eq $latestDir) {
        $newDir = "playground01"
    } else {
        [int] $counter = [Regex]::Match($latestDir.Name, "(\d+)").Groups[1].Value
        $newDir = "playground" + ($counter + 1).ToString("00")
    }

    $path = Join-Path "C:/temp" $newDir
    New-Item -ItemType Directory -Path $path | Out-Null
    Push-Location $path
    Copy-Item (Join-Path $HOME "Documents" "PowerShell" ".\resources\playground.fsx") "playground.fsx"
    New-Item -ItemType Directory -Name ".vscode" | Out-Null
    # copy settings so that the playground vs code gets a nice orange color thank to peacock extension
    Copy-Item (Join-Path $HOME "Documents" "PowerShell" ".\resources\settings.json") ".vscode\settings.json"
    # open the directory in vscode with the playground.fsx opened
    code . ./playground.fsx --disable-workspace-trust
}

function Update-PowerShell() {
    winget install --id Microsoft.PowerShell --source winget
}

function Update-Profile {
    New-ModuleManifest "./TempModuleToReloadProfile.psd1" -NestedModules "C:/git/powershell-profile/Profile.ps1"
    Import-Module      "./TempModuleToReloadProfile" -Global -Force
    Remove-Item        "./TempModuleToReloadProfile.psd1"
}

function Import-Conda {
    if (Test-Path "c:/Users/fku/AppData/Local/anaconda3/Scripts/conda.exe") {
        (& "c:/Users/fku/AppData/Local/anaconda3/Scripts/conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
    } else {
        Write-Output "Conda not found. Please run `winget install -e --id Anaconda.Anaconda3` to install conda."
    }
}

function Invoke-Login {
    . "C:\git\snips\ahk\logins.ahk"
}

Set-Alias -name ..     -value Set-LocationUp
Set-Alias -name cg     -value Set-LocationGit
Set-Alias -name ce     -value Set-LocationExe
Set-Alias -name bfg    -value Invoke-Bfg
Set-Alias -name curvie -value "IT.Curvie.exe"
Set-Alias -name c      -value Open-VsCodeDot
Set-Alias -name cn     -value code
Set-Alias -name total  -value Open-TotalCommander
Set-Alias -name t      -value Open-TotalCommander
Set-Alias -name sf     -value Start-Fiddler
Set-Alias -name rf     -value Reset-Fiddler
Set-Alias -name cgr    -value Clear-GitRepo
Set-Alias -name cgbs   -value Clear-GitBranchesStale
Set-Alias -name pg     -value playground
Set-Alias -name rr     -value Update-Profile
Set-Alias -name ic     -value Import-Conda
Set-Alias -name l      -value Invoke-Login
Set-Alias -name touch  -value New-Item

# added at the end as per documentation - https://ohmyposh.dev/docs/installation/prompt
oh-my-posh init pwsh | Invoke-Expression

$promptFunction = (Get-Command Prompt).ScriptBlock

function Prompt {
    Set-NodeExtraCaCertsForDCRepos
    $promptFunction.Invoke()
}
