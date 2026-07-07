class_name InputServer
extends Node

signal key_received(key_code:String)

const PORT:int = 7331

var _server:TCPServer = TCPServer.new()
var _client:StreamPeerTCP = null

func _ready()->void:
	var err:Error = _server.listen(PORT)
	if err != OK:
		push_warning("AvatarServer: could not bind port %d" % PORT)
	else:
		print("AvatarServer: listening on port %d" % PORT)
func update()->void:
	if _client == null or _client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		if _server.is_connection_available():
			_client = _server.take_connection()
		return
	var available:int = _client.get_available_bytes()
	if available <= 0: return

	var raw:String = _client.get_utf8_string(available)
	for line:String in raw.split("\n", false):
		_dispatch(line.strip_edges())
func _dispatch(msg:String)->void:
	if msg.is_empty(): return
	
	var pairs:PackedStringArray = msg.split(":", false, 2)
	if pairs.size() < 2:
		push_warning("AvatarServer: malformed message '%s'" % msg)
		return
	match(pairs[0]):
		"key": key_received.emit(pairs[1])
		_:push_warning("AvatarServer: unknown command '%s'" % pairs[0])
