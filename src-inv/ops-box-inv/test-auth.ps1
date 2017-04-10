$ErrorActionPreference= 'silentlycontinue'

#erase newfile.txt


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

                if ($SERVER) 
        {
                
                $D = $SERVER,$IP,$MANU,$SN -join ','

                $D >> output.csv
            
                }
                else
                {
                $NONWIN = 'NO Access'

        $D = $NONWIN,$IP -join ','

                $D >> output.csv
                
                }              

    }
    else
    {
                $NONWIN = 'Not Windows'

        $D = $NONWIN,$IP -join ','

                $D >> output.csv
    }

}

else 

{
                $NOPING = 'DOWN CANT PING'

                $D = $NOPING,$IP -join ','

                $D >> output.csv

}

#$INFO = get-WmiObject win32_bios -ComputerName "$IP" -Credential $Credential | select __SERVER,Manufacturer,SerialNumber 

#$SERVER = $INFO.__SERVER

#$MANU =  $INFO.Manufacturer

#$SN = $INFO.SerialNumber 

#$D = $SERVER,$IP,$MANU,$SN -join ','

#$D >> newfile.txt


}

