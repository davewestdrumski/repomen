#### This script is for taking inventory of the ops servers


$ErrorActionPreference= 'silentlycontinue'

$LIST = Get-Content list.txt




Write-Host Starting windows testing now......

$Credential = Get-Credential

ForEach ($IP in $LIST)

{
    Write-Host Testing $IP now ....

    $winconn = Test-NetConnection -ComputerName $IP -Port 135 -InformationLevel Quiet
    $linconn = Test-Netconnection -ComputerName $IP -Port 22 -InformationLevel Quiet

    If ($conn -Match "True")
        {
            write-host Hooray it worked for windows
        }
    Elif ($linconn -Match "True")
        {
            write-host Hooray it worked with Linux
        }

    write-host Not Windows or Linux
}

