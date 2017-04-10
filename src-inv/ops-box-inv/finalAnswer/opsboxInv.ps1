#### This script is for taking inventory of the ops servers


$ErrorActionPreference= 'silentlycontinue'

# $LIST = Get-Content ops-box-list.txt
$LIST = Get-Content hostretry.txt

# Get creds to test with

write-host Enter windows creds to test with (domain\username password)
$wincred = Get-Credential

write-host Enter linux creds to test with (username password)
$lincred = Get-Credential



ForEach ($IP in $LIST)

{
    Write-Host Testing $IP now ....

    $winconn = Test-NetConnection -ComputerName $IP -Port 135 -InformationLevel Quiet
    $linconn = Test-Netconnection -ComputerName $IP -Port 22 -InformationLevel Quiet

    If ($winconn -Match "True")

        {

            write-host Hooray it worked for $IP

            #Test login for windows

            $INFO = get-WmiObject win32_bios -ComputerName "$IP" -Credential $wincred | select __SERVER,Manufacturer,SerialNumber
			$SERVER = $INFO.__SERVER
			$MANU = $INFO.Manufacturer
			$SN = $INFO.SerialNumber
            $WINSVCS =  Get-WmiObject win32_service -ComputerName "$IP" -Credential $wincred | select Name,DisplayName,State,StartMode
			$SUCCESS = 'SUCCESS'

			if ($SERVER)
			{

					$D = $SERVER,$IP,$MANU,$SN,$SUCCESS -join ','

					$D >> output.csv
                    $WINSVCS >> output.csv
                    $SOFTWARE >> output.csv
			}

			else

			{
					$NBTSTAT = nbtstat -A $IP | findstr GROUP | findstr '<00>'

					$DOMAIN = $NBTSTAT | % 					{ $_.Split(" ") | select -first 5 } | select -last 1

					$ACCESS = 'NO Access'

					$D = $ACCESS,$IP,$DOMAIN -join ','

					$D >> noaccess.csv
			}

        }

    Elseif ($linconn -Match "True")

        {

            write-host Hooray it worked for $IP

            #Test login for linux

            Write-Host Testing login for $IP

            New-SSHSession -ComputerName "$IP" -Credential $lincred -Force -WarningAction SilentlyContinue | Out-Null

					$LINUXSERVER = Invoke-SSHCommand -SessionId 0 -Command "hostname"

					$MANU = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-manufacturer"

					$SN = Invoke-SSHCommand -SessionId 0 -Command "dmidecode -s system-serial-number "

					$CPU = Invoke-SSHCommand -SessionId 0 -Command "lscpu |awk '/^CPU/ || /Vendor/ || /Thread/ || /Socket/|| /Core(s)/' | xargs"

                    $RUNNING = Invoke-SSHCommandStream -SessionId 0 -Command "chkconfig --list; ps -ef"

					$NEWCPU = $CPU.ouput

					$NEWMANU = $MANU.Output

					$NEWSN = $SN.Output

			if($LINUXSERVER)

				{

					$LINUXOUT = "$NEWLINUXSERVER","$NEWMANU","$IP","$NEWSN","$NEWCPU" -join ','
					$LINUXOUT >> linuxOutput.csv
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

