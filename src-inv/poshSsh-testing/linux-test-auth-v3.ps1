# This script is for getting inventory and testing logins for linux servers

clear-content linuxOutput.csv

$LIST = Get-Content list.txt

$Credential = Get-Credential

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
