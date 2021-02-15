function Test-IsWindows {
    return $PSVersionTable.PSVersion.Major -le 5 -or $IsWindows
}

# Use emacs edit mode to make ^D, ^A, ^E, etc. work
Set-PSReadlineOption -EditMode Emacs

# zsh-like autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Disable the bell
Set-PSReadlineOption -BellStyle None

# Increase PSReadLine history
# See: https://github.com/PowerShell/PSReadLine/issues/1309
$MaximumHistoryCount = Get-Variable -Name MaximumHistoryCount `
    | Select-Object -ExpandProperty Attributes `
    | Select-Object -ExpandProperty MaxRange
Set-PSReadLineOption -MaximumHistoryCount $MaximumHistoryCount

# Function to get PSReadLine history because Get-History only shows the commands
# from the current session
function Get-PSReadLineHistory
{
    Get-Content (Get-PSReadlineOption).HistorySavePath
}

# NOTE: Only needed to get PSReadline to follow base16 conventions
# https://github.com/lukesampson/concfg/blob/master/README.md
#try { $null = Get-Command concfg -ea stop; concfg tokencolor -n enable } catch { }

# FZF
if (Test-IsWindows) {
    Remove-Item env:TERM -ErrorAction Ignore
}
Remove-PSReadlineKeyHandler 'Ctrl+r'
Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

# Git integration
Import-Module posh-git

# starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)

    # Add OSC 9;9 to prompt
    Rename-Item function:prompt prompt_starship

    function prompt() {
        prompt_starship

        $location = Get-Location
        if ($location.Provider -eq (Get-PSProvider FileSystem)) {
            Write-Host -NoNewline `
                "`u{1b}]9;9;`"$($location.ProviderPath)`"`u{1b}\"
        }
    }
}

# Enable colors with ls
Import-Module DirColors

# Set default file encoding to UTF-8 without BOM
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8NoBOM'

# Chocolatey profile
if (Test-IsWindows) {
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}

# Use less as the pager if it's installed
if (Test-IsWindows -and !$env:PAGER) {
    if (Get-Command less -ErrorAction SilentlyContinue) {
        $env:PAGER = 'less'
    }
}

# Set less' encoding to UTF-8 (primarily for git pager)
if (Test-IsWindows) {
    $env:LESSCHARSET = 'utf-8'
}

# Set COLORTERM on Windows (primarily for delta)
if (Test-IsWindows) {
    $env:COLORTERM = 'truecolor'
}

# GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh completion -s powershell | Out-String | Invoke-Expression
}

# bat
if (Get-Command bat -ErrorAction SilentlyContinue) {
    $env:BAT_THEME = 'base16-tomorrow-night'
}

# Wrapper to run commands shipped with git
if (Test-IsWindows) {
    $gbin = "$env:ProgramFiles\git\usr\bin"
    function gexec {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true, Position=0)]
            [string]$exe,
            [Parameter(Position=1, ValueFromRemainingArguments)]
            [string[]]$args
        )

        $oldPath = $env:PATH

        try {
            $env:PATH = $env:PATH.Insert(0, "$gbin;")
            & $exe $args
        } finally {
            $env:PATH = $oldPath
        }
    }
}
