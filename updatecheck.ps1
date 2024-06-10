$foregroundColor = "cyan"
$highlightColor = "Green"
$errorColor = "Red"

function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "This script need admin privileg" -ForegroundColor $errorColor
    exit
} else {
    
}

# Check if Module PSWindowsUpdate is installed
function Test-WindowsUpdateCommand {
    $test = Get-Command -Name Get-WindowsUpdate
}
if (Test-WindowsUpdateCommand -eq $false) {
    Write-Host "[*]Installing PSWindowsUpdate" -ForegroundColor $highlightColor
    Install-Module -Name PSWindowsUpdate -Confirm -AcceptLicense
} else {
    Write-Host "[*]Searching Updates..."
}

$updateSession = (Get-WindowsUpdate).KB
if ($updateSession.Count -eq 0) {
    Write-Host "No pending updates." -ForegroundColor $highlightColor
} else {
    Write-Host "Pending updates:" -ForegroundColor $highlightColor
    foreach ($update in $updateSession) {
        Write-Host $update.Title -ForegroundColor $foregroundColor
        $quest = Read-Host "You Want Install the updates"
        if ($quest -eq "y" -or $quest -eq "yes") {
            Get-WindowsUpdate -KBArticle $update.KB -Install -AcceptAll
        } else {
            Write-Host "GOOD BYE" -ForegroundColor Magenta
            exit
        }
    }
}
Write-Host "GOOD BYE" -ForegroundColor Magenta
