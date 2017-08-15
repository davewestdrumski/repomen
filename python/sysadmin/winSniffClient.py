import socket

# the public network interface
HOST = socket.gethostbyname(socket.gethostname())
PORT_LIST = [21, 22, 25, 53, 80, 443]

# create a raw socket and bind it to the public interface
for port in PORT_LIST:
    s = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_IP)
    s.bind((HOST, port))

# Include IP headers
s.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)

# receive all packages
s.ioctl(socket.SIO_RCVALL, socket.RCVALL_ON)

# receive a package
print(s.recvfrom(65565))

# disabled promiscuous mode
s.ioctl(socket.SIO_RCVALL, socket.RCVALL_OFF)