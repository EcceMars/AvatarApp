import socket
import time
import threading
from pynput.keyboard import KeyCode, Listener, Controller

HOST = "127.0.0.1"
PORT = 7331

controller = Controller()
keys_down  = set()

TYPING_KEYS = set(
	[KeyCode.from_char(c) for c in
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "0123456789"
	".,!?;:'\"-_()[]{}@#$%&*+=/<> "]
)

def connect():
	while True:
		try:
			s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			s.connect((HOST, PORT))
			print(f"keyboard_listener: connected on port {PORT}")
			return s
		except ConnectionRefusedError:
			time.sleep(0.5)

def send(sock, msg):
	try:
		sock.sendall((msg + "\n").encode("utf-8"))
		return True
	except (BrokenPipeError, OSError):
		return False

def key_to_str(key):
	if hasattr(key, "char") and key.char:
		return key.char
	return str(key).replace("Key.", "").replace("'", "")

def release_all():
	for key in list(keys_down):
		try:
			controller.release(key)
		except Exception:
			pass
	keys_down.clear()

sock = connect()
listener = None

def watch_connection():
	while True:
		time.sleep(2.0)
		try:
			sock.sendall(b"")
		except OSError:
			print("keyboard_listener: server gone, shutting down")
			if listener:
				listener.stop()
			return

def on_press(key):
	global sock
	keys_down.add(key)

	if key in TYPING_KEYS:
		msg = "key:" + key_to_str(key)
		if not send(sock, msg):
			sock = connect()
			send(sock, msg)

def on_release(key):
	keys_down.discard(key)

threading.Thread(target=watch_connection, daemon=True).start()

listener = Listener(on_press=on_press, on_release=on_release)
listener.start()
try:
	listener.join()
finally:
	release_all()
	send(sock, "key:flush")
	print("keyboard_listener: shutdown")
