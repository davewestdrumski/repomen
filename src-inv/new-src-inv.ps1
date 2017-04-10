##### This script was created by Tom Murphy and David West
##### The purpose of this script is to generate an inventory from a list of IPs and credentials
##### It requires Powershell 3.0, .NET 4.0, and Posh-SSH module to be installed
##### Documentation for this script can be found here https://wiki.nuancehce.com/display/IE/SRC+Inventory+PowerShell+Script

function Get-IPrange
{
<#
  .SYNOPSIS
    Get the IP addresses in a range
  .EXAMPLE
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20
  .EXAMPLE
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0
  .EXAMPLE
   Get-IPrange -ip 192.168.8.3 -cidr 24
#>

param
(
  [string]$start,
  [string]$end,
  [string]$ip,
  [string]$mask,
  [int]$cidr
)

function IP-toINT64 () {
  param ($ip)

  $octets = $ip.split(".")
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3])
}

function INT64-toIP() {
  param ([int64]$int)

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
}

if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)}
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) }
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)}
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)}
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))}

if ($ip) {
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring
} else {
  $startaddr = IP-toINT64 -ip $start
  $endaddr = IP-toINT64 -ip $end
}


for ($i = $startaddr; $i -le $endaddr; $i++)
{
  INT64-toIP -int $i

}

}

#### Clear out files from previous runs
if (test-path C:\tmp\dave\src-inv\notwin.csv) {clear-content C:\tmp\dave\src-inv\notwin.csv}
if (test-path C:\tmp\dave\src-inv\output.csv) {Clear-Content C:\tmp\dave\src-inv\output.csv}
if (test-path C:\tmp\dave\src-inv\linuxoutput.csv) {Clear-Content C:\tmp\dave\src-inv\linuxoutput.csv}
if (Test-Path C:\tmp\dave\src-inv\down.csv) {Clear-Content C:\tmp\dave\src-inv\down.csv}
if (Test-Path C:\tmp\dave\src-inv\noping.csv) {Clear-Content C:\tmp\dave\src-inv\noping.csv}
if (Test-Path C:\tmp\dave\src-inv\noaccess.csv) {Clear-Content C:\tmp\dave\src-inv\noaccess.csv}

#### Ask user for start and end ipaddresses

$start = read-host -prompt "Enter the starting ip"
$end = read-host -prompt "Enter the ending ip"


#### pass the ip range to get-iprange

Get-IPRange -start $start -end $end > list.txt

$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content list.txt

# Get creds to test with

write-host "Enter windows creds to test with (domain\username password)"
$wincred = Get-Credential

write-host "Enter linux creds to test with (username password)"
$lincred = Get-Credential



ForEach ($IP in $LIST)

{
    Write-Host Testing $IP now ....

    $winconn = Test-NetConnection -ComputerName $IP -Port 135 -InformationLevel Quiet
    $linconn = Test-Netconnection -ComputerName $IP -Port 22 -InformationLevel Quiet

    ####
    #### Try to get Windows info
    ####

    If ($winconn -Match "True")

        {

            write-host Hooray its Windows for $IP

            #Test login for windows

            $INFO = get-WmiObject win32_bios -ComputerName "$IP" -Credential $wincred | select __SERVER,Manufacturer,SerialNumber
            $SERVER = $INFO.__SERVER
            $MANU = $INFO.Manufacturer
            $SN = $INFO.SerialNumber
            $OSINFO = Get-WmiObject win32_OperatingSystem -ComputerName "$IP" -Credential $wincred  | Format-Table
            $DISKINFO = Get-WmiObject win32_DiskDrive -ComputerName "$IP" -Credential $wincred |Format-Table Partitions,Model,size
            $WINSVCS =  Get-WmiObject win32_service -ComputerName "$IP" -Credential $wincred | select Name,DisplayName,State,StartMode

            $SUCCESS = 'SUCCESS'

      if ($SERVER)
      {

          $D = $SERVER,$IP,$MANU,$SN,$SUCCESS -join ','

          $D >> output.csv
          $OSINFO >> output.csv
          $DISKINFO >> output.csv
          $WINSVCS >> output.csv

      }

      else

      {
          $NBTSTAT = nbtstat -A $IP | findstr GROUP | findstr '<00>'

          $DOMAIN = $NBTSTAT | %          { $_.Split(" ") | select -first 5 } | select -last 1

          $ACCESS = 'NO Access'

          $D = $ACCESS,$IP,$DOMAIN -join ','

          $D >> noaccess.csv
      }

        }
    ####
    #### Try to get Linux info
    ####

    Elseif ($linconn -Match "True")

        {

            write-host Hooray its Linux for $IP

            #Test login for linux

            Write-Host Testing login for $IP

            New-SSHSession -ComputerName "$IP" -Credential $lincred -Force -WarningAction SilentlyContinue | Out-Null

          $LINUXSERVER = Invoke-SSHCommand -SessionId 0 -Command "hostname"
          $MANU = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-manufacturer"
          $SN = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-serial-number "
          $CPU = Invoke-SSHCommand -SessionId 0 -Command "lscpu |awk '/^CPU/ || /Vendor/ || /Thread/ || /Socket/|| /Core(s)/' | xargs" | Format-Table Output
          $RUNNING = Invoke-SSHCommandStream -SessionId 0 -Command "chkconfig --list"
          $NEWLINUXSERVER = $LINUXSERVER.Output
          $NEWCPU = $CPU.Ouput
          $NEWMANU = $MANU.Output
          $NEWSN = $SN.Output

      if($LINUXSERVER)

        {

          $LINUXOUT = "$NEWLINUXSERVER","$NEWMANU","$IP","$NEWSN" -join ','
          $LINUXOUT >> linuxOutput.csv
          $CPU >> linuxOutput.csv
          $RUNNING >> linuxOutput.csv

          Remove-SSHSession -SessionId 0
        }



      else

          {
            # No Access
            $OS = 'Linux'
            $ACCESS = 'NO Access'
            $D = $ACCESS,$IP,$OS -join ','

            $D >> noaccess.csv
          }

        }
    Else
    {
        write-host Unreachable from this host
        $IP >> noping.csv
    }


}


