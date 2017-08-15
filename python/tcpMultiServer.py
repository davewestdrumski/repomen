import socket

def Main():
    host = "192.168.50.1"
    port_custom = 5000

    mySocket = socket.socket()
    mySocket.bind((host, port_custom))

    mySocket.listen(1)
    conn, addr = mySocket.accept()
    print('Connection from: ' + str(addr))

    while True:
        data = conn.recv(1024).decode()
        if not data:
            break
        print('from connected user: ' + str(data))

        data = str(data).upper()
        print('sending: ' + str(data))
        conn.send(data.encode())

    conn.close()

if __name__ == '__main__':
    Main()