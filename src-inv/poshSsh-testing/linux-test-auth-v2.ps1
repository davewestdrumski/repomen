# This script is for getting inventory and testing logins for linux servers

clear-content linuxOutput.csv

$LIST = Get-Content list.txt

$Credential = Get-Credential

ForEach ($IP in $LIST)

{

    New-SSHSession -ComputerName "$IP" -Credential $Credential -Force | Format-Wide -Property SessionId

    $LINUXSERVER = Invoke-SSHCommand -SessionId 0 -Command "hostname" | Format-Wide -Property Output
    write-output "hostname:" $LINUXSERVER
    $MANU = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-manufacturer" | Format-Wide -Property Output
    write-output "Manufacturer:" $MANU
    $SN = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-serial-number " |Format-Wide -Property Output
    write-output "SerialNumber:" $SN
    $SUCCESS = 'SUCCESS'

    $D = $LINUXSERVER,$IP,$MANU,$SN,$SUCCESS  -join ','
    write-output $D
    # $D >> linuxOutput.csv

    Remove-SSHSession -SessionId 0
}