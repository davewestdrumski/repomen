#### This script is for taking inventory of the ops servers


$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content sql-list.txt

#### Get creds to test with

# Windows
write-host Enter windows creds to test with (domain\username password)
$wincred = Get-Credential

#Linux
write-host Enter linux creds to test with (username password)
$lincred = Get-Credential



ForEach ($IP in $LIST)

{
    Write-Host Testing $IP now ....

    $winconn = Test-NetConnection -ComputerName $IP -Port 135 -InformationLevel Quiet
    $linconn = Test-Netconnection -ComputerName $IP -Port 22 -InformationLevel Quiet

    If ($winconn -Match "True")

        {

            write-host Hooray it worked for $winconn

            #Test login for windows

            $INFO = get-WmiObject win32_bios -ComputerName "$IP" -Credential $wincred | select __SERVER,Manufacturer,SerialNumber
            $SERVER = $INFO.__SERVER
            $MANU = $INFO.Manufacturer
            $SN = $INFO.SerialNumber
            $SUCCESS = 'SUCCESS'

            if ($SERVER)
            {

                    $D = $SERVER,$IP,$MANU,$SN,$SUCCESS -join ','

                    $D >> output.csv
            }

            else

            {
                    $NBTSTAT = nbtstat -A $IP | findstr GROUP | findstr '<00>'

                    $DOMAIN = $NBTSTAT | %                  { $_.Split(" ") | select -first 5 } | select -last 1

                    $ACCESS = 'NO Access'

                    $D = $ACCESS,$IP,$DOMAIN -join ','

                    $D >> noaccess.csv
            }

        }

    Elseif ($linconn -Match "True")

        {

            write-host Hooray it worked with $linconn

            #Test login for linux

            Write-Host Testing $IP login now

            New-SSHSession -ComputerName "$IP" -Credential $lincred -Force -WarningAction $ErrorActionPreference

                    $LINUXSERVER = Invoke-SSHCommand -SessionId 0 -Command "hostname"

                    $MANU = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-manufacturer"

                    $SN = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-serial-number "

                    $CPU = Invoke-SSHCommand -SessionId 0 -Command "lscpu |awk '/^CPU/ || /Vendor/ || /Thread/ || /Socket/|| /Core(s)/' | xargs"

                    $NEWCPU = $CPU.ouput

                    $NEWMANU = $MANU.Output

                    $NEWSN = $SN.Output

            if($LINUXSERVER)

                {

                    $LINUXOUT = "$NEWLINUXSERVER","$NEWMANU","$IP","$NEWSN","$NEWCPU" -join ','
                    $LINUXOUT >> linuxOutput.csv
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
        write-host Unreachable from this host $IP >> noping.csv
    }


}

