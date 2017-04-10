#### Ask user for start and end ipaddresses

$start = read-host -prompt "Enter the starting ip"
$end = read-host -prompt "Enter the ending ip"

#### load the get-iprange function
. C:\Users\thomas_murphy\auth2\Get-IPrange.ps1

#### pass the ip range to get-iprange.ps1

Get-IPRange -start $start -end $end > list.txt




$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content list.txt

$Credential = Get-Credential

ForEach ($IP in $LIST)

{

#### Lookup IP address and store results in files

$servername = nslookup $IP | select-string -Pattern "Name" > servernames.txt


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

$t = ''

}

#### Ask user for start and end ipaddresses

$start = read-host -prompt "Enter the starting ip"
$end = read-host -prompt "Enter the ending ip"

#### load the get-iprange function
. C:\Users\thomas_murphy\auth2\Get-IPrange.ps1

#### pass the ip range to get-iprange.ps1

Get-IPRange -start $start -end $end > list.txt




$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content list.txt

$Credential = Get-Credential

ForEach ($IP in $LIST)

{

#### Lookup IP address and store results in files

$servername = nslookup $IP | select-string -Pattern "Name" > servernames.txt


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

$t = ''

}

