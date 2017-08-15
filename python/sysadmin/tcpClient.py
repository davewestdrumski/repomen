import socket

def Main():
    host = '192.168.0.5'
    port = 5000

    s = socket.socket()
    s.connect((host, port))

    message = input('-> ')
    while message != 'q':
        s.send((message).encode())
        data = s.recv(1024).decode()

        print('Received from server: ' + data)

        message = input('-> ')
    s.close()

if __name__ == '__main__':
    Main()

