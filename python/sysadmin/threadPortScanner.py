import socket
import threading
from queue import Queue

print_lock = threading.Lock()

target = '192.168.0.5'

def portscan(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        con = s.connect((target, port))
        with print_lock:
            print('port', port, 'is open!!')
        con.close()
    except:
        pass

def threader():
    while True:
        worker = q.get()
        portscan(worker)
        q.task_done()

q = Queue()

for x in range(500):
    t = threading.Thread(target=threader)
    t.daemon = True
    t.start()
port_list = [21, 22, 23, 25, 53, 80, 131, 443, 445, 3389, 8080, 8443]

for worker in port_list:
    q.put(worker)

q.join()
