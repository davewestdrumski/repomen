##### This script is for gathering info about ops boxes to see what services they are running to determine which group is responsible for maintaining them
##### Is is based off of the src-inv script as they have very similar needs and requirements



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


