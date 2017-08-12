import socket
import os
import sys
from datetime import datetime

# Clear the screen
os.system('cls')

# Ask for imput
remoteServer = input('Enter a remote host to scan: ')
remoteServerIP = socket.gethostbyname(remoteServer)

# Print a nice banner with information about the host we are about to scan
print('-' * 60)
print('Please wait, scanning remote host', remoteServerIP)
print('-' * 60)

# Check what time the scan started
t1 = datetime.now()

# Using the range function to specify which ports (here it will scan all ports between 1 and 1024
# We also put in some error handling for catching errors

portList = [21, 22, 23,25, 53, 80, 135, 443, 445, ]

try:
    for port in portList:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex((remoteServerIP, port))
        if result == 0:
            print('Port {}:            Open'.format(port))
        else:
            print('Port {}             did not reply'.format(port))
        sock.close()

except KeyboardInterrupt:
    print('You pressed Ctrl+c')
    sys.exit()

except socket.gaierror:
    print('Hostname could not be resolved.  Exiting')
    sys.exit()

except socket.error:
    print('Could not connect to server')
    sys.exit()

# Checking the time again
t2 = datetime.now()

# Calculating the time it took to run the scan
total = t2 - t1
print('Scan completed in: ', total)