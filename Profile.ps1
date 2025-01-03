# https://github.com/dahlbyk/posh-git?tab=readme-ov-file#step-2-import-posh-git-from-your-powershell-profile
Import-Module posh-git
Import-Module "$psScriptRoot\play.psm1"

# https://stackoverflow.com/a/52485269/2377787
# Store previous command's output in $__
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

$env:Path += ";c:\programki"
$env:Path += ";c:\programki\gradle\gradle-8.0\bin\"

$env:DOTNET_ENVIRONMENT  = "Development"

# InCommodities stuff
$env:***REMOVED*** = "***REMOVED***"

# finances stuff
$env:***REMOVED*** = "***REMOVED***"

# cd git
function cg { Push-Location "c:\git" }

# cd up
function cu { set-location ".." }

# cd to .exes
function ce {
    $counter = 0
    [array] $foundExes =
    Get-ChildItem *.exe -Recurse `
    | Where-Object { $_.fullname.contains("bin") } `
    | Sort-Object LastWriteTime -Descending `
    | Group-Object DirectoryName `
    | ForEach-Object {
        [array] $filenames = $_.Group | ForEach-Object { , $_.Name }
        $mostRecent = $_.Group | ForEach-Object { $_.LastWriteTime } | Sort-Object -Descending | Select-Object -first 1
        @{path = $_.Name; files = $filenames; mostrecent = $mostRecent }
    } `
    | Sort-Object -Descending -Property mostrecent `
    | ForEach-Object { $counter = $counter + 1; $_.counter = $counter; , $_ }
    if ($foundExes.Length -eq 0) {
        Write-Host "none found"
    }
    elseif ($foundExes.Length -eq 1) {
        $foundExes `
        | Select-Object -First 1 `
        | % { $_.path } `
        | Push-Location
    }
    else {
        $foundExes | ForEach-Object { Write-Host "$($_.counter) $($_.path) $($_.files)" }
        $choice = Read-Host
        $gohere = $foundExes | Where-Object { $_.counter -eq $choice } | ForEach-Object { $_.path }
        Push-Location $gohere
    }
}

function Invoke-Bfg { java -jar C:\programs\bfg-repo-cleaner\bfg-1.14.0.jar $args }

function Open-VsCode {
    if ($args.Length -eq 0) {
        code .
    }
    else {
        code $args
    }
}

function Open-TotalCommander($path) {
    # https://www.ghisler.ch/wiki/index.php/Command_line_parameters
    $wd = Resolve-Path $path
    . "C:\Program Files\totalcmd\TOTALCMD64.EXE" $wd /O /T
}

function Curves {
    Get-ChildItem -File -Recurse -include @("*.fs", "*.json", "*.csv", "*.config", "*.py") | Select-String -Pattern "\d{6,}"
}

function Go-Crazy() {
    # regex from https://stackoverflow.com/questions/11040707/c-sharp-regex-for-guid
    $found = powercfg /l | sls crazy | % { $_ -match '(?im)[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?' }
    if ($found) {
        powercfg /SETACTIVE $matches[0]
        Write-Output "going crazy!!!!"
    }
    else {
        Write-Output "oh no - crazy profile not found!"
    }
}

function Start-Fiddler() {
    # to make fiddler work with .js I needed to:
    # - trust root cert for HTTP
    # - enable TLS1.2 in protocols for HTTPS
    $env:HTTP_PROXY = "http://127.0.0.1:8888"
    $env:HTTPS_PROXY = "http://127.0.0.1:8888"
    $env:NODE_TLS_REJECT_UNAUTHORIZED = 0
    Start-Process "C:\programki\fiddlerClassic\Fiddler.exe"
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

function Clean-Git($masterBranch = "master") {
    git remote prune origin # remove remote branches that don't exist on origin
    $to_be_removed = git branch --merged $masterBranch --all | Where-Object { ! $_.Contains($masterBranch) }
    $local, $remote = $to_be_removed | Group-Object -Property { $_.Contains("remotes/origin") }
    foreach ($branch in $local.Group) {
        git branch -d $branch.Trim()
    }
    foreach ($branch in $remote.Group) {
        $trimmed = $branch.Replace("remotes/origin/", "").Trim()
        git push origin --delete $trimmed
    }
    # TODO - remove stale branches
    # $a = git branch --all --format="%(authoremail) xxx %(committerdate) xxx %(refname)"
    # $split = $a | % { return ,($_ -split " xxx ") }
    # $x = $split | % { return ,@([datetime]::ParseExact($_[1],"ddd MMM d HH:mm:ss yyyy zzzz",$null),$_[0],$_[1]) }
    # $threshold = get-date | % { $_.AddDays(-180)}
}

function Set-Node-Extra-Ca-Certs-For-DC-Repos() {
    $dcRepos = @("c:\git\IT.DataCapture", "c:\git\IT.ContinuousDataCapture")
    $currentDir = Get-Location
    $areWeInADcRepo = $dcRepos.Where({$_ -eq $currentDir}).Count -gt 0
    if ($areWeInADcRepo) {
        $env:NODE_EXTRA_CA_CERTS = "./extraCerts.pem"
    }
    else {
        Remove-Item Env:\NODE_EXTRA_CA_CERTS
    }
}

set-alias -name ..     -value cu
set-alias -name bfg    -value Invoke-Bfg
set-alias -name curvie -value "IT.Curvie.exe"
set-alias -name c      -value Open-VsCode
set-alias -name cn     -value code # vscode new
set-alias -name total  -value Open-TotalCommander
set-alias -name t      -value Open-TotalCommander
set-alias -name sf     -value Start-Fiddler
set-alias -name rs     -value Reset-Fiddler

# added at the end as per documentation - https://ohmyposh.dev/docs/installation/prompt
oh-my-posh init pwsh | Invoke-Expression

$promptFunction = (Get-Command Prompt).ScriptBlock

function Prompt {
    Set-Node-Extra-Ca-Certs-For-DC-Repos
    $promptFunction.Invoke()
}
