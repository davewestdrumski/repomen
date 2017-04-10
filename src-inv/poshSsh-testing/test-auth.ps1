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


#### Ask user for start and end ipaddresses

$start = read-host -prompt "Enter the starting ip"
$end = read-host -prompt "Enter the ending ip"


#### pass the ip range to get-iprange

Get-IPRange -start $start -end $end > list.txt

$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content list.txt

$Credential = Get-Credential

ForEach ($IP in $LIST)

{

if (test-connection $IP)

{

 $t = New-Object Net.Sockets.TcpClient "$IP", 135

    if($t.Connected)
    {
        $INFO = get-WmiObject win32_bios -ComputerName "$IP" -Credential $Credential | select __SERVER,Manufacturer,SerialNumber
        $SERVER = $INFO.__SERVER
        $MANU = $INFO.Manufacturer
        $SN = $INFO.SerialNumber
    	  $SUCCESS = 'SUCCESS'

	if ($SERVER)
        {

	$D = $SERVER,$IP,$MANU,$SN,$SUCCESS  -join ','

	$D >> output.csv
	}
	else

	{

	$NBTSTAT = nbtstat -A $IP | findstr GROUP | findstr '<00>'

	$DOMAIN = $NBTSTAT | % { $_.Split(" ") | select -first 5 } | select -last 1

	$ACCESS = 'NO Access'

        $D = $ACCESS,$IP,$DOMAIN -join ','

	$D >> output.csv

	}

    }
    else
    {

         $D = $IP

	       $D >> notwin.csv

         # This script is for getting inventory and testing logins for linux servers

          clear-content linuxOutput.csv

          $LIST = Get-Content notwin.csv

          # $Credential = Get-Credential

          ForEach ($IP in $LIST)

          {

              New-SSHSession -ComputerName "$IP" -Credential $Credential -Force

              $LINUXSERVER = Invoke-SSHCommand -SessionId 0 -Command "hostname"

              $MANU = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-manufacturer"

              $SN = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-serial-number "

              $D = $LINUXSERVER.output,$IP,$MANU.output,$SN.output |format-list #>> linuxOutput.csv
              $D + '' >> linuxOutput.csv

              Remove-SSHSession -SessionId 0
          }
    }

}

else

{
	$NOPING = 'DOWN CANT PING'

	$D = $NOPING,$IP -join ','

	$D >> down.csv

}

$t = ''

}

