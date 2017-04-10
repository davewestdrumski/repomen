#### This script is for taking inventory of the ops servers


$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content ops-box-list.txt




Write-Host Starting windows testing now......

$Credential = Get-Credential

ForEach ($IP in $LIST)



{

Write-Host Testing $IP now ....

if (test-connection $IP)

{

 $t = New-Object Net.Sockets.TcpClient "$IP", 135
 $l = New-Object Net.Sockets.TcpClient "$IP", 22

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

                $D >> noaccess.csv
            }
    }
    elif($l.Connected)
    {
    write-host Enter linux credentials....

    {
        New-SSHSession -ComputerName "$IP" -Credential $Credential -Force

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

    }

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

else

{
    $NOPING = 'DOWN CANT PING'

    $D = $NOPING,$IP -join ','

    $D >> down.csv

}
}

