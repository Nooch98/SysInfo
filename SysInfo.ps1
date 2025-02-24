# Version: 0.2.3

$localFile = "$env:USERPROFILE\Documents\PowerShell\Scripts\Sysinfo.ps1"
$remoteFile = "$env:USERPROFILE\Documents\PowerShell\Scripts\Sysinfo_temp.ps1"
$configFile = "$env:USERPROFILE\Documents\PowerShell\Scripts\config.json"
$config = Get-Content $configFile | ConvertFrom-Json
$url = "https://raw.githubusercontent.com/Nooch98/SysInfo/main/SysInfo.ps1"
$logFile = "$env:USERPROFILE\Documents\PowerShell\Scripts\update_log.txt"

# Definimos los cambios en una variable
$updates = @"
Updates 0.2.3:
- Integrated extended network info, driver verification and disk SMART status into the Additional Info section
- Virtual machine and hyper-v detection
- Detailed ram memory detection
"@

function Show-Popup {
    param (
        [string]$message,
        [string]$title = "Last Update"
    )

    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, $title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

function Prompt-User {
    param (
        [string]$message,
        [string]$defaultOption = "Y"
    )

    $response = Read-Host "$message (Y/N) [Default: $defaultOption]"
    if ([string]::IsNullOrEmpty($response)) {
        $response = $defaultOption
    }
    return $response.ToUpper() -eq "Y"
}

# Read the current configuration for development mode
$developmentMode = $false
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    $developmentMode = $config.development_mode
}

$VerbosePreference = if ($developmentMode) { 'Continue' } else { 'SilentlyContinue' }

# Ask if the user wants to change the development mode
if (Prompt-User "The current mode is $(if ($developmentMode) { 'Development' } else { 'Production' }). Do you want to change it?") {
    $developmentMode = -not $developmentMode
    $config.development_mode = $developmentMode
    $config | ConvertTo-Json | Set-Content $configFile
    Write-Host "Mode changed to $(if ($developmentMode) { 'Development' } else { 'Production' })." -ForegroundColor Yellow
}

# Check if we're in a development environment
if ($developmentMode) {
    Write-Host "Development mode enabled. Skipping update check..." -ForegroundColor Yellow
} else {
    # Function to get script version
    function Get-ScriptVersion {
        param (
            [string]$filePath
        )

        if (Test-Path $filePath) {
            $content = Get-Content -Path $filePath -Raw
            if ($content -match "# Version: (\d+\.\d+\.\d+)") {
                return $matches[1]
            }
        }
        return $null
    }

    # Function to download file with SSL certificate check
    function Download-FileWithSSLCheck {
        param (
            [string]$url,
            [string]$outputPath
        )

        try {
            Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $outputPath -ErrorAction Stop
            Write-Host "File downloaded successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download file. Error: $_" -ForegroundColor Red
            exit
        }
    }

    # Ask if the user wants to proceed with the update
    if (Prompt-User "Do you want to check for updates?") {
        # Download the remote file with error handling
        Download-FileWithSSLCheck -url $url -outputPath $remoteFile

        # Get versions
        $localVersion = Get-ScriptVersion -filePath $localFile
        $remoteVersion = Get-ScriptVersion -filePath $remoteFile

        Write-Host "Current version: $localVersion"
        Write-Host "New version: $remoteVersion"

        # Compare versions
        if ($localVersion -ne $null -and $remoteVersion -ne $null) {
            if ($remoteVersion -gt $localVersion) {
                Write-Host "New version is available. Updating script..." -ForegroundColor Green
                Move-Item -Path $remoteFile -Destination $localFile -Force
                "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - Script updated to version $remoteVersion" | Out-File -FilePath $logFile -Append
                Show-Popup -message $updates
                & $localFile
            } else {
                Write-Host "No update needed. Current script is up-to-date." -ForegroundColor Yellow
                Remove-Item -Path $remoteFile
            }
        } else {
            Write-Host "Failed to retrieve version information." -ForegroundColor Red
            Remove-Item -Path $remoteFile
        }
    } else {
        Write-Host "Update canceled by user." -ForegroundColor Yellow
    }
}

if ($developmentMode) {
    Write-Host "Development mode enabled. Verbose output will be shown." -ForegroundColor Yellow
} else {
}

# Logo del sistema
$systemLogo = @"
                            ┌─────────────┬─────────────┐
                            │             │             │
                            │             │             │
                            │             │             │
                            │             │             │
                            ├─────────────┼─────────────┤
                            │             │             │
                            │             │             │
                            │             │             │
                            │             │             │
                            └─────────────┴─────────────┘
           
"@

# Colores
$highlightColor = "Green"
$foregroundColor = "Cyan"
$errorColor = "Red"

Write-Host -NoNewline ("`e]9;4;3;50`a")

Write-Verbose "Attempting to get computer information"
$computer = Get-ComputerInfo

# Obtener información del sistema
$device = $computer.CsSystemFamily 
$os = $computer.OsName
$kernel = $computer.OsVersion
$processor = $computer.CsProcessors
$logicalprocessors = $computer.CsNumberOfLogicalProcessors
$memory = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$motherboard = (Get-WmiObject Win32_BaseBoard).Product
$updatestatus = Get-Service -Name wuauserv | Select-Object -ExpandProperty Status

# System Uptime
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptimeFormatted = [System.DateTime]::Now - $uptime

# PowerShell Update Check
$updateNeeded = $false
$currentversion = $PSVersionTable.PSVersion.ToString()
$gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
$latestReleaseinfo = Invoke-RestMethod -Uri $gitHubApiUrl
$latestversion = $latestReleaseinfo.tag_name.Trim('v')
if ($currentversion -lt $latestversion) {
    $updateNeeded = $true
}

$powershellupdate = if ($updateNeeded) {
}

# Obtener la resolución del monitor
$monitors = Get-CimInstance -Namespace "root/CIMV2" -Class Win32_VideoController
$resolutions = $monitors | ForEach-Object { ($_).VideoModeDescription -split ' x ' | Select-Object -First 2 }
foreach ($resolution in $resolutions) {
}

# Obtener la versión de Windows
$windowsVersion = $computer.WindowsCurrentVersion

# Obtiene el numero de serie
$serialnumber = $computer.OsSerialNumber

# Obtiene el usuario asociado
$asociateuser = $computer.WindowsRegisteredOwner

# Obtiene el nombre de la bios
$biosversion = $computer.BiosVersion

# Obtiene la provedora de la bios
$biosmanufacture = $computer.BiosManufacturer

# Obtiene el tipo de bios
$biostipe = $computer.BiosFirmwareType

# Obtener información del sistema de archivos
$diskUsage = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } |  Select-Object -Property DeviceID, FreeSpace, Size
foreach ($disk in $diskUsage) {
    $diskFreeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskUsedSpaceGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $diskTotalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
    $diskFreePercentage = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
    $diskUsedPercentage = [math]::Round(100 - $diskFreePercentage)
}

# Obtener información de red
$network = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }
$ipAddress = Invoke-RestMethod -Uri "http://ipinfo.io/json"
$ipAddres = $ipAddress.ip
$isp = $ipAddress.org
$location = $ipAddress.city
$macAddress = $network.MACAddress[0]
$hostname = $env:COMPUTERNAME
$networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -notlike '*VMware*' } | Select-Object Name, Status, MacAddress, LinkSpeed
foreach ($adapter in $networkAdapters) {
}

# Obtener información de la red WiFi
$wifi = Get-NetConnectionProfile
$wifiInfo = if ($wifi) {
    $wifiinterface = $wifi.InterfaceAlias
    $wifiname = $wifi.Name
    $wificonnectivityIPv6 = $wifi.IPv6Connectivity
    $wifiConnectivityipV4 = $wifi.IPv4Connectivity
    "SSID: $wifiname, Interface: $wifiinterface, Connectivity IPv6: $wificonnectivityIPv6, connectivity IPv4: $wifiConnectivityipV4"
} else {
    "WiFi not available"
}

# Obtener información de la batería (si es aplicable)
$battery = Get-WmiObject Win32_Battery
$batteryInfo = if ($battery) {
    $batteryTimeRemaining = $battery.EstimatedRunTime
    $batteryStatus = $battery.Status
    $batteryID = $battery.DeviceID
    "Battery Level: $($battery.EstimatedChargeRemaining)%, Status: $batteryStatus, ID: $batteryID"
} else {
    "Battery not available"
}

# Obtener información adicional del sistema operativo
$osArchitecture = $computer.OsArchitecture

# Obtener información del entorno de desarrollo
# Aquí deberías obtener la información relevante sobre el entorno de desarrollo, como el IDE utilizado, la versión del compilador, etc.
if ($Host.Name -eq "ConsoleHost") {
    $developmentEnvironment = "PowerShell Console"
} elseif ($Host.Name -eq "Visual Studio Code Host") {
    $developmentEnvironment = "Visual Studio Code"
} elseif ($Host.Name -eq "Python Host") {
    $developmentEnvironment = "Python Console"
} else {
    $developmentEnvironment = "Unknown Terminal"
}


# Obtener información sobre la utilización de la CPU
$cpu = Get-WmiObject -Class Win32_Processor
$cpu | ForEach-Object {
    $name = $_.Name
    $maxClockSpeedGHz = [math]::round($cpu.MaxClockSpeed / 1000, 1)
}
$cpuLoad = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
$cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

# Obtener información sobre parches de seguridad
$securityPatches = Get-HotFix | Where-Object { $_.Description -eq "Security Update" }
$recentPatch = $securityPatches | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1

# Obtiene Nombre de la tarjeta grafica
Write-Host "Fetching GPU information, this may take few seconds..." -ForegroundColor $highlightColor
$graphic = Get-CimInstance -Namespace "root/CIMV2" -ClassName Win32_VideoController
$graphiccard = $graphic.Name
if ($graphic.Name -Like "*NVIDIA*") {
    $nvidiaVersionOutput = (nvidia-smi --version) | FINDSTR "DRIVER Version" | Select-Object -First 1
    $graphicversion = $nvidiaVersionOutput -replace "DRIVER version\s+:\s+", ""
} else {
    $graphicversion = $graphic.DriverVersion
}
# Ejecutar dxdiag y guardar la salida en un archivo temporal
$dxdiagOutputFile = "dxdiag_output.txt"
dxdiag /t $dxdiagOutputFile

# Esperar a que el archivo se cree y se complete
$maxWaitTime = 60 # Segundos
$waitTime = 0
$fileCreated = $false

while (-not (Test-Path $dxdiagOutputFile) -and $waitTime -lt $maxWaitTime) {
    Start-Sleep -Seconds 1
    $waitTime++
}

$memoryValueGB = 0
if (Test-Path $dxdiagOutputFile) {
    # Verificar si el archivo ha terminado de escribirse comprobando el tamaño
    $lastSize = (Get-Item $dxdiagOutputFile).length
    while ($true) {
        Start-Sleep -Seconds 1
        $newSize = (Get-Item $dxdiagOutputFile).length
        if ($newSize -eq $lastSize) {
            break
        }
        $lastSize = $newSize
    }

    # Leer el archivo y buscar la primera línea que contiene "Dedicated Memory"
    $dedicatedMemoryLines = Select-String -Path $dxdiagOutputFile -Pattern "Dedicated Memory"

    if ($dedicatedMemoryLines.Count -gt 0) {
        # Seleccionar la primera línea
        $dedicatedMemoryLine = $dedicatedMemoryLines[0].Line
        
        # Extraer el valor de memoria dedicada utilizando una expresión regular
        $memoryValueMatch = [regex]::Match($dedicatedMemoryLine, '(\d+)')
        
        if ($memoryValueMatch.Success) {
            $memoryValueMB = [int]$memoryValueMatch.Value  # Convertir a entero

            # Convertir de MB a GB
            $memoryValueGB = [math]::Round($memoryValueMB / 1024, 2)  # Redondear a 2 decimales

        } else {
            Write-Host "The value of dedicated memory could not be extracted from the line: $dedicatedMemoryLine." -ForegroundColor $errorColor
        }
    } else {
        Write-Host "The 'Dedicated Memory' line was not found in the dxdiag file." -ForegroundColor $errorColor
        $gpuNameLines = Select-String -Path $dxdiagOutputFile -Pattern "Card name|Display Memory"

        if ($gpuNameLines.Count -gt 0) {
            $gpuLine = $gpuNameLines[0].Line

            if ($gpuLine -match "Card name") {
                $gpuName = $gpuLine -replace "Card name: ", ""
            }

            if ($gpuLine -match "Display Memory") {
                # Extraer el valor de memoria de video (para tarjetas no NVIDIA)
                $memoryValueMatch = [regex]::Match($gpuLine, '(\d+)')

                if ($memoryValueMatch.Success) {
                    $memoryValueMB = [int]$memoryValueMatch.Value  # Convertir a entero

                    # Convertir de MB a GB
                    $memoryValueGB = [math]::Round($memoryValueMB / 1024, 2)  # Redondear a 2 decimales

                    Write-Host "Detected Display Memory: $memoryValueGB GB" -ForegroundColor $infoColor
                } else {
                    Write-Host "The value of display memory could not be extracted from the line: $gpuLine." -ForegroundColor $errorColor
                }
            }
        }
    }

    # Eliminar el archivo temporal
    Remove-Item $dxdiagOutputFile
} else {
    Write-Host "The dxdiag file was not created within the expected time." -ForegroundColor $errorColor
}

# Function to get real-time GPU memory usage if possible (for NVIDIA GPUs)
function Get-NvidiaGPUMemoryUsage {
    try {
        $nvidiaSmiPath = "c:\Windows\system32\nvidia-smi.exe"
        if (Test-Path $nvidiaSmiPath) {
            $output = & $nvidiaSmiPath --query-gpu=memory.used --format=csv,noheader,nounits
            $gpuMemoryUsedMB = $output.Trim()
            return "$gpuMemoryUsedMB MB used"
        } else {
            return "NVIDIA GPU not detected or 'nvidia-smi' not found."
        }
    } catch {
        return "Error retrieving GPU memory usage: $_"
    }
}

function control_users {
    $uac = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"
    if ($uac.EnabledLUA -eq 1) {
        $uac1 = Write-Host ("{0,-26} : {1}" -f 'UAC Status', 'Enable') -ForegroundColor $foregroundColor
    } else {
        $uac2 = Write-Host ("{0,-26} : {1}" -f 'UAC Status', 'Disable') -ForegroundColor $foregroundColor
    }
}

# Friewall status
$firewall = Get-NetFirewallProfile
$firewallStatus = @()
foreach ($profile in $firewall) {
    $firewallStatus += "$($profile.Name): $($profile.Enabled)"
}
$firewallname = $firewallStatus -join ', '

# Antivirus info
$antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct
$antivirusname = $antivirus.displayName
$antivirusstate = Get-Service -Name WinDefend | Select-Object -ExpandProperty Status
$gpuuse = Get-NvidiaGPUMemoryUsage
$processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, WS
$eventLogs = Get-EventLog -LogName Application -Newest 10
$powerPlan = powercfg /getactivescheme
$powerPlanName = $powerPlan -replace '.*\((.*?)\).*', '$1'
$runningServicesCount = (Get-Service | Where-Object { $_.Status -eq 'Running' }).Count
function ping {
  $ping = Test-NetConnection -ComputerName google.com -WarningAction SilentlyContinue
  if ($ping.PingSucceeded) {
    $ping1 = Write-Host ("{0,-26} : {1}" -f 'Network Status', 'OK') -ForegroundColor $foregroundColor
  } else {
    $ping2 = Write-Host ("{0,-26} : {1}" -f 'Network Status', 'Failed') -ForegroundColor $foregroundColor
  }
}
$SystemInfo = @{}
$virtualizationSupport = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty VirtualizationFirmwareEnabled
$hyperV = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like "Microsoft-Hyper-V-All" }
$SystemInfo["Virtualization in firmware"] = if ($virtualizationSupport) { "Enabled" } else { "Disable" }
$SystemInfo["Hyper-V"] = if ($hyperV -and $hyperV.State -eq "Enabled") { "Installed and enabled" } else { "Not Installed and Disabled" }
$vmCheck = Get-CimInstance -Class Win32_ComputerSystem
$vmManufacturer = $vmCheck.Manufacturer
$vmModel = $vmCheck.Model
$SystemInfo["Machine Tipe"] = if ($vmManufacturer -match "VMware|Virtual|Hyper|KVM|QEMU") { 
    "Virtual ($vmManufacturer - $vmModel)" 
} else { 
    "Físic" 
}
$memoryModules = Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, PartNumber, Capacity, Speed, FormFactor, SerialNumber
$memoryFormFactor = @{
    0  = "Desconocido"
    1  = "Otro"
    2  = "SIP"
    3  = "DIP"
    4  = "ZIP"
    5  = "SOJ"
    6  = "Propietario"
    7  = "SIMM"
    8  = "DIMM"
    9  = "TSOP"
    10 = "PGA"
    11 = "RIMM"
    12 = "SODIMM"
    13 = "SRIMM"
    14 = "FB-DIMM"
}
$MemoryDetails = @()
foreach ($module in $memoryModules) {
    $MemoryDetails += "Fabricante: $($module.Manufacturer) | Model: $($module.PartNumber) | Capacity: {0} GB | Velocity: {1} MHz | Tipe: {2} | Serial: $($module.SerialNumber)" -f ([math]::Round($module.Capacity / 1GB, 2)), $module.Speed, $memoryFormFactor[$module.FormFactor]
}

if ($MemoryDetails.Count -eq 0) {
    $MemoryDetails = "No modules detected."
}

$SystemInfo["Details of RAM"] = $MemoryDetails -join "`n"
$driverCount = (Get-WmiObject Win32_PnPSignedDriver).Count
$diskSMART = Get-PhysicalDisk | ForEach-Object { "$($_.DeviceID) [$($_.MediaType)]: $($_.HealthStatus), $($_.OperationalStatus), Size: $([math]::Round($_.Size/1GB,2)) GB" } -join " | "

Write-Host -NoNewline ("`e]9;4;0;50`a")
Clear-Host

# Mostrar la información con los logos
Write-Host @"
$systemLogo
"@ -ForegroundColor Blue

# Formatear y mostrar la información a la derecha del logo
Write-Host "-------------------------------------SOFTWARE-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-16} : {1}" -f 'Device', $device) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Operating System', $os) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Kernel', $kernel) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Windows Build', $windowsVersion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'OS Architecture', $osArchitecture) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Security Patch', $recentPatch.HotFixID + ', Date ' + $recentPatch.InstalledOn) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Windows Update', $updatestatus) -ForegroundColor $foregroundColor
Write-Host ("System Uptime    : {0} days {1} hours {2} minutes" -f $uptimeFormatted.Days, $uptimeFormatted.Hours, $uptimeFormatted.Minutes) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Serial Number', $serialnumber) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Associate User', $asociateuser) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Manufacture', $biosmanufacture) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios version', $biosversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Type', $biostipe) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

# Mostrar informacion del Hardware
Write-Host "--------------------------------------HARDWARE-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-16} : {1}" -f 'Motherboard', $motherboard) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'CPU', "$name($logicalprocessors CPUs)~$maxClockSpeedGHz GHz") -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}%" -f 'CPU Usage', $cpuUsage) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1} GB" -f "$($disk.DeviceID)","Free Space $diskFreeSpaceGB") -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1} GB" -f 'Memory', ($memory.Sum / 1GB)) -ForegroundColor $foregroundColor
foreach ($key in $SystemInfo.Keys) {
    Write-Host ("{0,-16} : {1}" -f $key, $SystemInfo[$key]) -ForegroundColor $foregroundColor
}
Write-Host ("{0,-16} : {1}" -f 'GPU', $graphiccard) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU USE', $gpuuse) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU Memory', $memoryValueGB + ' GB') -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Drivers Version', $graphicversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Resolution', $resolution) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Battery Info', $batteryInfo) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Energy Plan', $powerPlanName) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

# Mostrar la información adicional
Write-Host "-------------------------------------ADITIONAL INFO------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Development Environment', $developmentEnvironment, $currentTerminal) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'PowerShell Update', $currentversion + $powershellupdate) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Process Running', $runningServicesCount) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1} GB (Free: {2} GB, Used: {3} GB, Free: {4}%, Used: {5}%)" -f ('Disk ' + $disk.DeviceID), $diskTotalSpaceGB, $diskFreeSpaceGB, $diskUsedSpaceGB, $diskFreePercentage, $diskUsedPercentage) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Disk SMART', $diskSMART) -ForegroundColor $foregroundColor
ping
Write-Host ("{0,-26} : {1}" -f 'ISP', $isp) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Pubilc IP Address', $ipAddres) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'MAC Address', $macAddress) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Location', $location) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Hostname', $hostname) -ForegroundColor $foregroundColor
Write-Host ("Adapter                    : {0}, Status: {1}, mac: {2}, Speed: {3}" -f $adapter.Name, $adapter.Status, $adapter.MacAddress, $adapter.LinkSpeed) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'WiFi Info', $wifiInfo) -ForegroundColor $foregroundColor
# Integración de la información extendida de IPs en Additional Info, asignando un color único a cada adaptador
Write-Host ("{0,-26} : " -f 'Ext. IP Configs') -NoNewline -ForegroundColor $foregroundColor

# Obtiene todas las configuraciones con direcciones IPv4
$netConfigs = Get-NetIPConfiguration | Where-Object { $_.IPv4Address }

# Lista de colores para asignar a cada adaptador (se reciclará si hay más adaptadores que colores)
$colors = @("Green", "Cyan", "Magenta", "Yellow", "Blue", "Red", "DarkGray", "DarkCyan")
$adapterIndex = 0

foreach ($config in $netConfigs) {
    # Asigna el color según el índice actual
    $adapterColor = $colors[$adapterIndex % $colors.Count]
    $adapterIndex++

    # Muestra el alias de la interfaz, las IPs y los DNS con el color asignado
    Write-Host ("[Interface: $($config.InterfaceAlias)] ") -NoNewline -ForegroundColor $adapterColor
    $ips = ($config.IPv4Address | ForEach-Object { $_.IPAddress }) -join ", "
    Write-Host ("IP: $ips ") -NoNewline -ForegroundColor $adapterColor
    $dns = if ($config.DNSServer) { $config.DNSServer.ServerAddresses -join ", " } else { "N/A" }
    Write-Host ("(DNS: $dns) ") -NoNewline -ForegroundColor $adapterColor
    Write-Host "| " -NoNewline -ForegroundColor $foregroundColor
}
Write-Host ""
Write-Host ("{0,-26} : {1}" -f 'Driver Count', $driverCount) -ForegroundColor $foregroundColor
Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

# Mostrar informacion de seguridad
Write-Host "-------------------------------------SECURITY INFO--------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Firewall', $firewallname) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Antivirus', $antivirusname) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Status', $antivirusstate) -ForegroundColor $foregroundColor
control_users
Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor
Write-Host "AUTHOR: Nooch98" -ForegroundColor Yellow
