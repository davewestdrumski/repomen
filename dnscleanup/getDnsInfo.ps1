# THis script tries to get the OS info from a list of servers

#### This script is for installing the check mk agent on linux servers
Set-StrictMode -Version 2.0


# $ErrorActionPreference= 'silentlycontinue'

# List of servers/ips to use
# $LIST = '.\asc-cmk-import.txt'
$LIST = (get-content .\list.txt)

$separator = echo =====================================================

#clear out results files
Clear-Content .\winservers.txt
Clear-Content .\linservers.txt
Clear-Content .\fail.txt

$wincred = Get-Credential -credential david_west
$lincred = Get-Credential -credential root

foreach ($server in $LIST)
{

    # Test which port each host is listening on
    Write-Output "Testing $server now ...."

    $winconn = Test-NetConnection -ComputerName $server -Port 3389 -InformationLevel Quiet -WarningAction SilentlyContinue
    $linconn = Test-Netconnection -ComputerName $server -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue

    If ($winconn -Match "True")

        {

            Write-Output "$server is listening on port 3389"
            $win = Get-WmiObject -credential $wincred -ComputerName $server -Class win32_operatingSystem |Select-Object csname,Caption,osarchitecture
            $windns = Get-WmiObject -credential $wincred -ComputerName $server  -Class win32_networkadapterconfiguration | Select-Object DNSServerSearchOrder -unique

            $separator
            $win
            $windns
            $separator

            $separator >> winservers.txt
            $server >> winservers.txt
            $win >> winservers.txt
            $windns >> winservers.txt
            $separator >> winservers.txt

       
        }
    
    elseif ($linconn -match "True")
        {
            $lin = Write-Output "$server is listening on port 22"
            New-SSHSession -ComputerName $server -Credential $lincred  -Force -WarningAction SilentlyContinue | Out-Null
            $lin = Invoke-SSHCommand -SessionId 0 -Command "cat /etc/redhat-release" | Select-Object Output
            $lindns = Invoke-SSHCommand -SessionId 0 -Command "cat /etc/resolv.conf" | Select-Object Output
            $lindnsnontrh = Invoke-SSHCommand -SessionId 0 -Command "cat/etc/issues" | Select-Object Output

            $separator            
            $lin
            $lindns
            $separator

            $separator >> linservers.txt
            $lin >> linservers.txt
            $lindns >> linservers.txt
            $separator >> linservers.txt

            Remove-SSHSession -SessionId 0


        }
    
    else
        {
             $separator
             $noConn = Write-Output "$server is not reachable on ports 22 or 3389 from this host"
             $separator

             $separator >> fail.txt
             $noConn >> fail.txt
             $separator >> fail.txt
        }
}