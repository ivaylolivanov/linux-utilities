Set-PSReadLineOption -EditMode Emacs

# Set the ExecutionPolicy to RemoteSigned:
Set-ExecutionPolicy Unrestricted -Scope CurrentUser;

# Style default PowerShell Console
$shell = $Host.UI.RawUI;
$shell.BackgroundColor = "Black";
$shell.ForegroundColor = "White";

Set-Location "$HOME\Projects";

function emacsd
{
    Set-Location -Path "C:\Users\ivayl\AppData\Roaming\.emacs.d";
}

function roamd
{
    Set-Location -Path "C:\Users\ivayl\AppData\Roaming\Documents\org-roam";
}

function projects
{
    Set-Location -Path "C:\Users\ivayl\Projects";
}

function prompt
{
    $directoryColor = "Yellow";
    $branchColor = "Green";
    $resetColor = "White";

    $gitBranch = $null;
    $gitDirectory = (Get-Command git -ErrorAction SilentlyContinue).Path;
    if ($gitDirectory)
    {
        $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null;
    }

    $currentDirectory = if ($gitBranch)
    {
        $pwd.Path.Replace($HOME, "~") + " ";
    }
    else
    {
        $pwd.Path;
    }

    $branchText = if ($gitBranch)
    {
        "($gitBranch) ";
    }
    else
    {
        "";
    }

    Write-Host -NoNewline -ForegroundColor $directoryColor "$currentDirectory";
    Write-Host -NoNewline -ForegroundColor $branchColor "$branchText";
    Write-Host -NoNewline -ForegroundColor $resetColor "`n> ";
    return " ";
}

# Disable Powershell 7's suggestions.
# Normally, it would have been great to have them but they are done in a
# despicable manner. They are getting in the way of the work rather than
# helping.
Set-PSReadLineOption -PredictionSource None
# Set Autocomplete to "tab" instead "right-arrow";
# Set-PSReadLineKeyHandler -Chord "Tab" -Function ForwardChar;

# Import posh-git
Import-Module posh-git;
