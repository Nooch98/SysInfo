$archivoLocal = "$env:USERPROFILE\Documents\PowerShell\Scripts\Sysinfo.ps1"
$archivoRemoto = "$env:USERPROFILE\Documents\PowerShell\Scripts\Sysinfo_temp.ps1"
$url = "https://raw.githubusercontent.com/Nooch98/SysInfo/main/SysInfo.ps1"

Invoke-RestMethod -Uri $url -OutFile $archivoRemoto
$hashLocal = Get-FileHash -Path $archivoLocal -Algorithm SHA256 | Select-Object -ExpandProperty Hash
$hashRemoto = Get-FileHash -Path $archivoRemoto -Algorithm SHA256 | Select-Object -ExpandProperty Hash
if ($hashLocal -eq $hashRemoto) {
    Write-Host "You have the latest update installed..." -ForegroundColor Green
    Remove-Item $archivoRemoto
} else {
    Write-Host "Installing the latest update..." -ForegroundColor Magenta
    Remove-Item $archivoLocal
    Move-Item $archivoRemoto $archivoLocal
    Write-Host "You have the latest update installed..." -ForegroundColor Green
}

# Logo del sistema
$systemLogo = @"
                                                        ....iilll
                                            ....iilllllllllllll
                                ....iillll  lllllllllllllllllll
                            iillllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            llllllllllllll  lllllllllllllllllll
                            `^^^^^^lllllll  lllllllllllllllllll
                                ````^^^^  ^^lllllllllllllllll
                                                ````^^^^^^llll                
"@

# Colores
$foregroundColor = "cyan"
$highlightColor = "Green"
$errorColor = "Red"

Write-Host -NoNewline ("`e]9;4;3;50`a")

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
$networkAdapters = Get-NetAdapter | Select-Object Name, Status, LinkSpeed
foreach ($adapter in $networkAdapters) {
}

# Obtener información de la red WiFi
$wifi = Get-NetConnectionProfile
$wifiInfo = if ($wifi) {
    $wifiinterface = $wifi.InterfaceAlias
    $wifiname = $wifi.Name
    $wificonnectivity = $wifi.IPv6Connectivity
    "SSID: $wifiname, Interface: $wifiinterface, Connectivity: $wificonnectivity"
} else {
    "WiFi not available"
}

# Obtener información de la batería (si es aplicable)
$battery = Get-WmiObject Win32_Battery
$batteryInfo = if ($battery) {
    $batteryTimeRemaining = $battery.EstimatedRunTime
    $batteryStatus = $battery.Status
    "Battery Level: $($battery.EstimatedChargeRemaining)%, Status: $batteryStatus"
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
$cpuUsage = $cpuLoad.Average

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
    }

    # Eliminar el archivo temporal
    Remove-Item $dxdiagOutputFile
} else {
    Write-Host "The dxdiag file was not created within the expected time." -ForegroundColor $errorColor
}

# Friewall status
$firewall = Get-NetFirewallProfile
$firewallname1 = $firewall.Name | Select-Object -First 1
$firewallstatusinfo = $firewall.Enabled | Select-Object -First 1

# Antivirus info
$antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct
$antivirusname = $antivirus.displayName
$antivirusstate = Get-Service -Name WinDefend | Select-Object -ExpandProperty Status

Write-Host -NoNewline ("`e]9;4;0;50`a")
Clear-Host

# Mostrar la información con los logos
Write-Host @"
$systemLogo
"@ -ForegroundColor $highlightColor

# Formatear y mostrar la información a la derecha del logo
Write-Host "-------------------------------------SOFTWARE-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-16} : {1}" -f 'Device', $device) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Operating System', $os) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Kernel', $kernel) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Windows Build', $windowsVersion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'OS Architecture', $osArchitecture) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Security Patch', $recentPatch.HotFixID + ', Date ' + $recentPatch.InstalledOn) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Windows Update', $updatestatus) -ForegroundColor $foregroundColor
Write-Host ("{Uptime,-26}  : System Uptime: {0} days {1} hours {2} minutes" -f $uptimeFormatted.Days, $uptimeFormatted.Hours, $uptimeFormatted.Minutes) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Serial Number', $serialnumber) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Associate User', $asociateuser) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Manufacture', $biosmanufacture) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios version', $biosversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Type', $biostipe) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

Write-Host "--------------------------------------HARDWARE-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-16} : {1}" -f 'Motherboard', $motherboard) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'CPU', "$name($logicalprocessors CPUs)~$maxClockSpeedGHz GHz") -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}%" -f 'CPU Usage', $cpuUsage) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1} GB" -f 'Memory', ($memory.Sum / 1GB)) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU', $graphiccard) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU Memory', $memoryValueGB + ' GB') -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Drivers Version', $graphicversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Resolution', $resolution) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Battery Info', $batteryInfo) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

# Mostrar la información adicional
Write-Host "-------------------------------------ADITIONAL INFO------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Development Environment', $developmentEnvironment, $currentTerminal) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1} GB (Free: {2} GB, Used: {3} GB, Free: {4}%, Used: {5}%)" -f ('Disk ' + $disk.DeviceID), $diskTotalSpaceGB, $diskFreeSpaceGB, $diskUsedSpaceGB, $diskFreePercentage, $diskUsedPercentage) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'ISP', $isp) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Pubilc IP Address', $ipAddres) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'MAC Address', $macAddress) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Location', $location) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Hostname', $hostname) -ForegroundColor $foregroundColor
Write-Host ("{Adapter,-26} : Adapter: {0}, Status: {1}, Speed: {2}" -f $adapter.Name, $adapter.Status, $adapter.LinkSpeed) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'WiFi Info', $wifiInfo) -ForegroundColor $foregroundColor
Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

Write-Host "-------------------------------------SECURITY INFO--------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Firewall', $firewallname1) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Status', $firewallstatusinfo) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Antivirus', $antivirusname) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Status', $antivirusstate) -ForegroundColor $foregroundColor
Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor
