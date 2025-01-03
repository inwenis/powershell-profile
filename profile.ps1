# https://github.com/dahlbyk/posh-git?tab=readme-ov-file#step-2-import-posh-git-from-your-powershell-profile
import-module posh-git
Import-Module "$psScriptRoot\play.psm1"
# https://stackoverflow.com/a/52485269/2377787
# Store previous command's output in $__
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

$env:Path += ";c:\programki"
$env:Path += ";c:\programki\gradle\gradle-8.0\bin\"
$env:Path += ";c:\Users\fku\OneDrive - In Commodities A S\Documents\Apps\"

$env:DOTNET_Environment = "Development"
$env:***REMOVED*** = "***REMOVED***"

$env:NODE_EXTRA_CA_CERTS = "./extraCerts.pem"

$env:***REMOVED*** = "***REMOVED***"

Function cg { pushd c:\git }
function ce {
    $counter = 0
    [array] $foundExes =
    ls *.exe -Recurse `
    | ? { $_.fullname.contains("bin") } `
    | sort lastwritetime -Descending `
    | group DirectoryName `
    | % {
        [array] $filenames = $_.Group | % { , $_.Name }
        $mostRecent = $_.Group | % { $_.LastWriteTime } | sort -Descending | select -first 1
        @{path = $_.Name; files = $filenames; mostrecent = $mostRecent }
    } `
    | sort -Descending -Property mostrecent `
    | % { $counter = $counter + 1; $_.counter = $counter; , $_ }
    if ($foundExes.Length -eq 0) {
        Write-Host "none found"
    }
    elseif ($foundExes.Length -eq 1) {
        $foundExes `
        | select -First 1 `
        | % { $_.path } `
        | pushd
    }
    else {
        $foundExes | % { Write-Host "$($_.counter) $($_.path) $($_.files)" }
        $choice = Read-Host
        $gohere = $foundExes | ? { $_.counter -eq $choice } | % { $_.path }
        pushd $gohere
    }
}

function cd_up { set-location ".." }
function bfgFun { java -jar C:\programs\bfg-repo-cleaner\bfg-1.14.0.jar $args }
function vsCodeFun {
    if ($args.Length -eq 0) {
        code .
    }
    else {
        code $args
    }
}
set-alias -name ..     -value cd_up
set-alias -name bfg    -value bfgFun
set-alias -name curvie -value "IT.Curvie.exe"
set-alias -name c -value vsCodeFun
set-alias -name cn -value code # vscode new

function curves {
    ls -File -Recurse -include @("*.fs", "*.json", "*.csv", "*.config", "*.py") | sls -Pattern "\d{6,}"
}

function total($path) {
    # https://www.ghisler.ch/wiki/index.php/Command_line_parameters
    $wd = Resolve-Path $path
    . "C:\Program Files\totalcmd\TOTALCMD64.EXE" $wd /O /T
}

function go-crazy() {
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

function start-fiddler() {
    # to make fiddler work with .js I needed to:
    # - trust root cert for HTTP
    # - enable TLS1.2 in protocols for HTTPS
    $env:HTTP_PROXY = "http://127.0.0.1:8888"
    $env:HTTPS_PROXY = "http://127.0.0.1:8888"
    $env:NODE_TLS_REJECT_UNAUTHORIZED = 0
    Start-Process "C:\programki\fifflerClassic\Fiddler.exe"
    Write-Output "tip - you can filter requests you see in fiddler by using Rules/User-Agents and set it to axios"
    Write-Output "you can also find the Windows proxy settings and disable the proxy that fidder set. This way you should only see request from your console."
    Write-Output "Remember that intercepting requests will not work for scrapers that use certificates and a cutom agent"
}

function reset-fiddler() {
    Remove-Item Env:\HTTP_PROXY
    Remove-Item Env:\HTTPS_PROXY
    Remove-Item Env:\NODE_TLS_REJECT_UNAUTHORIZED
    # to-do remove windows proxies here (remove = unset/disable)
}

function clean-git($masterBranch = "master") {
    git remote prune origin # remove remote branches that don't exist on origin
    $to_be_removed = git branch --merged $masterBranch --all | ? { ! $_.Contains($masterBranch) }
    $local, $remote = $to_be_removed | Group-Object -Property { $_.Contains("remotes/origin") }
    foreach ($branch in $local.Group) {
        git branch -d $branch.Trim()
    }
    foreach ($branch in $remote.Group) {
        $trimmed = $branch.Replace("remotes/origin/", "").Trim()
        git push origin --delete $trimmed
    }
}

# $a = git branch --all --format="%(authoremail) xxx %(committerdate) xxx %(refname)"
# $split = $a | % { return ,($_ -split " xxx ") }
# $x = $split | % { return ,@([datetime]::ParseExact($_[1],"ddd MMM d HH:mm:ss yyyy zzzz",$null),$_[0],$_[1]) }
# $threshold = get-date | % { $_.AddDays(-180)}
Register-ArgumentCompleter -native -CommandName curvie -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorColumn, $lowestLevel)
    $all = @(
        "--help"
        "--input"
        "--compare"
        "--show"
        "--plot"
        "--version"
        "--update"
        "--forceupdate"
        "--listversions"
    )

    $all | Where-Object { $_ -like "$wordToComplete*" }
}

# https://ohmyposh.dev/docs/installation/prompt
# added at the end as per documentation
oh-my-posh init pwsh | Invoke-Expression
