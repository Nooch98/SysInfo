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

$computer = Get-ComputerInfo

# Obtener información del sistema
$device = $computer.CsSystemFamily 
$os = $computer.OsName
$kernel = $computer.OsVersion
$processor = $computer.CsProcessors
$logicalprocessors = $computer.CsNumberOfLogicalProcessors
$memory = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$hofixes = $computer.OsHotFixes

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
$diskUsage = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -Property DeviceID, FreeSpace, Size
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
$adapterConnectionStatus = if ($networkAdapter.NetConnectionStatus) { "Connected" } else { "Disconnected" }

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
$osArchitecture = $computer.CsSystemType

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
$cpuLoad = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
$cpuUsage = $cpuLoad.Average

# Obtener información sobre parches de seguridad
$securityPatches = Get-HotFix | Where-Object { $_.Description -eq "Security Update" }
$recentPatch = $securityPatches | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1

# Obtiene Nombre de la tarjeta grafica
$graphic = Get-CimInstance -Namespace "root/CIMV2" -ClassName Win32_VideoController
$graphiccard = $graphic.Name
$graphicversion = $graphic.DriverVersion
$graphicMemory = $graphic.AdapterRAM / 1GB  # Convertir de bytes a gigabytes

# Friewall status
$firewall = Get-NetFirewallProfile
$firewallname1 = $firewall.Name | Select-Object -First 1
$firewallstatusinfo = $firewall.Enabled | Select-Object -First 1

# Antivirus info
$antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct
$antivirusname = $antivirus.displayName
$antivirusstate = $antivirus.productState

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
Write-Host ("{0,-16} : {1}" -f 'Security Patch', $recentPatch.HotFixID) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Serial Number', $serialnumber) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Associate User', $asociateuser) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Manufacture', $biosmanufacture) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios version', $biosversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Bios Type', $biostipe) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

Write-Host "-------------------------------------HARDWARE-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-16} : {1}" -f 'CPU', $processor.Name) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}%" -f 'CPU Usage', $cpuUsage) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1} GB" -f 'Memory', ($memory.Sum / 1GB)) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU', $graphiccard) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'GPU Memory', $graphicMemory + 'GB') -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Drivers', $graphicversion) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Resolution', $resolution) -ForegroundColor $foregroundColor
Write-Host ("{0,-16} : {1}" -f 'Battery Info', $batteryInfo) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

# Mostrar la información adicional
Write-Host "-------------------------------------ADITIONAL INFO-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Development Environment', $developmentEnvironment, $currentTerminal) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1} GB (Free: {2} GB, Used: {3} GB, Free: {4}%, Used: {5}%)" -f ('Disk ' + $disk.DeviceID), $diskTotalSpaceGB, $diskFreeSpaceGB, $diskUsedSpaceGB, $diskFreePercentage, $diskUsedPercentage) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'ISP', $isp) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Pubilc IP Address', $ipAddres) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'MAC Address', $macAddress) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Location', $location) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Hostname', $hostname) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Adapter Status', $adapterConnectionStatus) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'WiFi Info', $wifiInfo) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor

Write-Host "-------------------------------------SECURITY INFO-----------------------------------------------------" -ForegroundColor $highlightColor
Write-Host ("{0,-26} : {1}" -f 'Firewall', $firewallname1) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Status', $firewallstatusinfo) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Antivirus', $antivirusname) -ForegroundColor $foregroundColor
Write-Host ("{0,-26} : {1}" -f 'Status', $antivirusstate) -ForegroundColor $foregroundColor
Write-Host "---------------------------------------------------------------------------------------------------" -ForegroundColor $highlightColor
