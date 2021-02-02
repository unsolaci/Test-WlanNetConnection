<#PSScriptInfo
.VERSION     1.0.0
.DESCRIPTION Gets Wlan signal and packet loss details.
.AUTHOR      Wojciech Ros (code@unsola.ci)
.COPYRIGHT   Copyright (C) 2021 Wojciech Ros (code@unsola.ci)
.LICENSEURI  http://www.apache.org/licenses/LICENSE-2.0
.GUID        c05b391c-6e3e-4563-b079-92fa9bf491b0
#>

<#
.SYNOPSIS
    Gets Wlan signal and packet loss details.
#>
[CmdletBinding()]
param (
    # Specifies the number of tests. The default value is 4.
    [int]$Count = 4,
    # Specifies the interval between tests, in seconds.
    [int]$Delay,
    # Specifies the number of echo requests to send in each test. The default value is 4.
    [int]$PingCount = 4
)
function Get-Timestamp {
    return (Get-Date -Format "yyyy-MM-dd_HH-mm-ssK") -replace ':','-'
}

#TODO what if multiple interfaces?
function Get-NetshWlanInterfaceProperties {
    param (
        [string[]]$Properties = (
            "Name", 
            "Description", 
            "GUID", 
            "Physical address", 
            "State", 
            "SSID", 
            "BSSID", 
            "Network type", 
            "Radio type", 
            "Authentication", 
            "Cipher", 
            "Connection mode", 
            "Channel", 
            "Receive rate (Mbps)", 
            "Transmit rate (Mbps)", 
            "Signal", 
            "Profile"
        )
    )
    
    $NetshWlanInterfaceProperties = New-Object -TypeName PSObject
    $NetshWlanShowInterfacesOutput = (netsh.exe wlan show interfaces) | Out-String
    $Properties | ForEach-Object {
        $NetshWlanShowInterfacesOutput -match "\b$_\b\s+:\s+(.*)" | Out-Null
        $NetshWlanInterfaceProperties `
            | Add-Member `
                -MemberType NoteProperty `
                -Name "$_" `
                -Value $Matches[1]
    }

    return $NetshWlanInterfaceProperties
}

function Test-WlanNetConnection {
    param (
        # Specifies the number of tests. The default value is 4.
        [int]$Count = 4,
        # Specifies the interval between tests, in seconds.
        [int]$Delay,
        # Specifies the number of echo requests to send in each test. The default value is 4.
        [int]$PingCount = 4
    )

    for ($i = 0; $i -lt $Count; $i++) {
        $NetshWlanInterfaceProperties = Get-NetshWlanInterfaceProperties

        $TestConnectionObject = Test-Connection `
            -Count $PingCount `
            -ComputerName `
                "8.8.8.8", `
                "1.1.1.1"

        $TotalPingCount = $PingCount * 2
        
        $TotalResponseTime = 0
        $TestConnectionObject | ForEach-Object {
            $TotalResponseTime += $_.ResponseTime
        }
        [int]$AverageResponseTime = ( $TotalResponseTime / $TestConnectionObject.Count )

        $collection = [PSCustomObject]@{
            Source              = $TestConnectionObject[0].PSComputerName
            Destination         = $TestConnectionObject[0].Address
            IPV4Address         = $TestConnectionObject[0].IPV4Address
            IPV6Address         = $TestConnectionObject[0].IPV6Address
            Bytes               = $TestConnectionObject[0].Bytes
            AverageResponseTime = $AverageResponseTime
            PacketsSent         = $TotalPingCount
            PacketsReceived     = $TestConnectionObject.Count
            PacketsLost         = ( $TotalPingCount - $TestConnectionObject.Count )
            PacketLoss          = ( 100% - ( $TestConnectionObject.Count / $TotalPingCount ) ).ToString("P")
            WlanInterface       = $NetshWlanInterfaceProperties.Description
            SSID                = $NetshWlanInterfaceProperties.SSID
            BSSID               = $NetshWlanInterfaceProperties.BSSID
            Channel             = $NetshWlanInterfaceProperties.Channel
            Signal              = $NetshWlanInterfaceProperties.Signal
        }

        $collection

        Start-Sleep -Seconds $Delay
    }
}

Test-WlanNetConnection `
    -Count $Count `
    -Delay $Delay `
    -PingCount $PingCount
