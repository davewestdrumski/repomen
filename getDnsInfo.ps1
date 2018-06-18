# This script gets the DNS server info of a server from a list of servers

Set-StrictMode -Version 2.0


$ErrorActionPreference= 'silentlycontinue'

$LIST = (cat .\tliserverlist.txt)

foreach  ($SERVER in $LIST)
{
        #write-host $SERVER
        #Get-WmiObject -ComputerName $SERVER -Class win32_operatingsystem
        #$OSINFO = (Get-WmiObject -ComputerName $SERVER -Class win32_operatingsystem |select-object caption,osarchitecture)
echo =====================================================
$SERVER
#$DNSINFO

        #$DnsINFO = Get-WmiObject -ComputerName $SERVER  -Class win32_networkadapterconfiguration | Format-Table DNSServerSearchOrder
        #$DnsInfo
        # $DnsRESULTS = $DnsINFO | select-object `@{Name="OS Name";Expression={$_.Caption}}` | out-string).trim()
        $DNS = Get-WmiObject -ComputerName $SERVER  -Class win32_networkadapterconfiguration | Select-Object DNSServerSearchOrder -unique
        $DNS
echo =====================================================
}