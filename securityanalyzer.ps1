# Verify if the script is executing by admin
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "This script requires admin privileges" -ForegroundColor Red
    exit
}

# Function to analyze firewall status
function Check-Firewall {
    $firewallState = Get-NetFirewallProfile | Select-Object -Property Name, Enabled
    $firewallEnabled = $true
    foreach ($profile in $firewallState) {
        if ($profile.Enabled -eq $false) {
            Write-Host "Firewall in the profile $($profile.Name) is disabled" -ForegroundColor Red
            $firewallEnabled = $false
        } else {
            Write-Host "Firewall in the profile $($profile.Name) is enabled" -ForegroundColor Green
        }
    }
    return $firewallEnabled
}

# Function to Check Admin Users
function Check-AdminUsers {
    $adminGroupSID = "S-1-5-32-544"
    $adminGroupName = (Get-LocalGroup | Where-Object { $_.SID -eq $adminGroupSID }).Name

    if ($adminGroupName) {
        $adminUsers = Get-LocalGroupMember -Group $adminGroupName
        Write-Host "Users in Admin Group ($adminGroupName):" -ForegroundColor Cyan
        foreach ($user in $adminUsers) {
            Write-Host $user.Name
        }
        return $true
    } else {
        Write-Host "The Admin Group could not be found." -ForegroundColor Red
        return $false
    }
}

# Function to check password policies
function Check-PasswordPolicy {
    $policy = Get-LocalUser | Where-Object { $_.PasswordExpires -ne $null -or $_.PasswordChangeableDate -ne $null }

    if ($policy) {
        Write-Host "Password Policies of the local users:" -ForegroundColor Cyan
        $policy | Format-Table -AutoSize
        return $true
    } else {
        Write-Host "No password policies configured for local users." -ForegroundColor Red
        return $false
    }
}

# Function to check the status of windows update service
function Check-WindowsUpdate {
    $wuStatus = Get-Service -Name wuauserv
    if ($wuStatus.Status -eq 'Running') {
        Write-Host "Windows Update Service is running" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Windows Update Service is stopped" -ForegroundColor Red
    }
}

# Function to check Windows Defender Status
function Check-Antivirus {
    $antivirusStatus = Get-MpComputerStatus
    if ($antivirusStatus.AntivirusEnabled) {
        Write-Host "The Antivirus (Windows Defender) is enabled" -ForegroundColor Green
        return $true
    } else {
        Write-Host "The Antivirus (Windows Defender) is disabled" -ForegroundColor Red
        return $false
    }
}

# Function to check for open ports
function Check-OpenPorts {
    $listeningPorts = netstat -an | Select-String "LISTENING"
    $establishedPorts = netstat -an | Select-String "ESTABLISHED"
    
    if ($listeningPorts -or $establishedPorts) {
        Write-Host "Open ports detected:" -ForegroundColor Red
        
        if ($listeningPorts) {
            Write-Host "`nListening ports:" -ForegroundColor Yellow
            $listeningPorts | ForEach-Object { Write-Host $_ }
        }
        
        if ($establishedPorts) {
            Write-Host "`nEstablished connections:" -ForegroundColor Yellow
            $establishedPorts | ForEach-Object { Write-Host $_ }
        }
        
        return $true
    } else {
        Write-Host "No open ports detected." -ForegroundColor Green
        return $false
    }
}

# Function to check for inactive user accounts
function Check-InactiveAccounts {
    $inactiveAccounts = Get-LocalUser | Where-Object { $_.Enabled -eq $false }
    if ($inactiveAccounts) {
        Write-Host "Inactive user accounts detected:" -ForegroundColor Red 
        Write-Host "use command: Get-LocalUser | Where-Object { $_.Enabled -eq $false } to see inactive accounts" -ForegroundColor Yellow
        $inactiveAccounts | Format-Table -Property Name, Enabled, Description -AutoSize
        return $true
    } else {
        Write-Host "No inactive user accounts detected." -ForegroundColor Green
        return $false
    }
}

# Function to check recent security events
function Check-SecurityEvents {
    $events = Get-EventLog -LogName Security -EntryType FailureAudit -Newest 10
    if ($events) {
        Write-Host "Recent security events detected:" -ForegroundColor Red
        $events | Format-Table -AutoSize
        return $true
    } else {
        Write-Host "No recent security events." -ForegroundColor Green
        return $false
    }
}

# Function to calculate score
function Calculate-Score {
    param (
        [string]$firewallEnabled,
        [string]$adminUsersConfigured,
        [string]$passwordPolicyConfigured,
        [string]$windowsUpdateRunning,
        [string]$antivirusEnabled,
        [string]$openPorts,
        [string]$inactiveAccountsDetected,
        [string]$recentSecurityEventsDetected
    )

    $totalScore = 0
    $disabledAspects = @()

    if ($firewallEnabled) {
        $totalScore += 10
    } else {
        $disabledAspects += "Firewall"
    }

    if ($adminUsersConfigured) {
        $totalScore += 10
    } else {
        $disabledAspects += "Admin Users"
    }

    if ($passwordPolicyConfigured) {
        $totalScore += 10
    } else {
        $disabledAspects += "Password Policy"
    }

    if ($windowsUpdateRunning) {
        $totalScore += 10
    } else {
        $disabledAspects += "Windows Update"
    }

    if ($antivirusEnabled) {
        $totalScore += 10
    } else {
        $disabledAspects += "Antivirus"
    }

    if ($openPorts) {
        $totalScore += 10
    } else { 
        $disabledAspects += "Open Ports" 
    }
    
    if (-not $recentSecurityEventsDetected) {
        $totalScore += 10
    } else {
        $disabledAspects += "Recent Security Events"
    }

    return $totalScore, $disabledAspects
}

function Fortify-System {
    param(
        [string]$firewallEnabled,
        [string]$windowsUpdateRunning
    )

    if (-not $firewallEnabled) {
        Write-Host "Enabling Firewall..." -ForegroundColor Yellow
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    }

    if (-not $windowsUpdateRunning) {
        Write-Host "Starting Windows Update Service..." -ForegroundColor Yellow
        Start-Service -Name wuauserv
    }
}


# Execute Audit and Calculate Score
Write-Host "Starting Security Audit..." -ForegroundColor Yellow
$firewallEnabled = (Check-Firewall)
$adminUsersConfigured = (Check-AdminUsers)
$passwordPolicyConfigured = (Check-PasswordPolicy)
$windowsUpdateRunning = (Check-WindowsUpdate)
$antivirusEnabled = (Check-Antivirus)
$openPortsDetected = (Check-OpenPorts)
$inactiveAccountsDetected = (Check-InactiveAccounts)
$recentSecurityEventsDetected = (Check-SecurityEvents)
Write-Host "Security Audit Finishing." -ForegroundColor Yellow

# Calculate Score
$totalScore, $disabledAspects = Calculate-Score -firewallEnabled $firewallEnabled -adminUsersConfigured $adminUsersConfigured -passwordPolicyConfigured $passwordPolicyConfigured -windowsUpdateRunning $windowsUpdateRunning -antivirusEnabled $antivirusEnabled -openPortsDetected $openPortsDetected -inactiveAccountsDetected $inactiveAccountsDetected -recentSecurityEventsDetected $recentSecurityEventsDetecte

Write-Host "Security Score: $totalScore/70" -ForegroundColor Magenta
Write-Host "Disabled Aspects: $($disabledAspects -join ', ')" -ForegroundColor Yellow

# Ask user if they want to fortify the system
$quest = Read-Host "Do you want to fortify the system? (y/n)"
if ($quest -eq "y" -or $quest -eq "yes") {
    Fortify-System -firewallEnabled $firewallEnabled -windowsUpdateRunning $windowsUpdateRunning
} else {
    Write-Host "System fortification skipped." -ForegroundColor Yellow
}