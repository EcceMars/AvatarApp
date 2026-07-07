class_name UserInput
extends Node

enum MIC_LEVEL { SILENT, MID, LOUD }
const MIC_LEVELS:Dictionary[MIC_LEVEL, float] = {
	MIC_LEVEL.LOUD: -5.0,
	MIC_LEVEL.MID: -40.0,
	MIC_LEVEL.SILENT: -80.0,
	}
var _START_:bool = false

var mouth:MouthAnimation
var talk_buffer_length:float = 0.8
var _is_talking:bool = false
var _buffer:float = 0.0

var mic_level:MIC_LEVEL = MIC_LEVEL.SILENT
var viewport:Viewport
var audio_bus_id:int = -1
var typing_rate:float = 0.0
var key_window:float = 0.2
var last_key_time:float = -INF

var _delta:float = 0.0
var _mic_volume:float = -INF
var mouse_pos:Vector2 = Vector2.ZERO
var mouse_speed:float = 0.0
var mouse_displacement:float = 0.0

var _mouse_positions:Array[Vector2] = []
var _mouse_timestamps:Array[float] = []
var _mouse_window:float = 0.15
var _key_timestamps:Array[float] = []
var _key_frame:float = 0.0
var _last_key:String = ''

func setup(
	_viewport:Viewport,
	_server:InputServer,
	input_stream:AudioStreamPlayer,
	_mouth_node:MouthAnimation = null,
	_buffer_length:float = 0.8
)->void:
	viewport = _viewport
	audio_bus_id = AudioServer.get_bus_index(input_stream.bus)
	mouth = _mouth_node
	talk_buffer_length = _buffer_length
	
	_server.key_received.connect(_on_key_received)
	_START_ = true

func update(delta:float):
	if not _START_: return

	_key_frame -= delta
	if _key_frame <= 0.0:
		typing_rate = 0.0
		_key_timestamps = []

	_delta = delta
	_update_mic()
	_update_mouse()
	
	_update_mouth(delta)

func _update_mouth(delta:float)->void:
	if not mouth:
		return
		
	if _mic_volume != -INF and _mic_volume > MIC_LEVELS[MIC_LEVEL.MID]:
		_buffer = talk_buffer_length
		_is_talking = true
	else:
		if _buffer > 0.0:
			_buffer -= delta
		_is_talking = _buffer > 0.0
	
	mouth.talking = _is_talking

func _update_mouse()->void:
	var now:float = Time.get_ticks_msec() / 1000.0
	mouse_pos = viewport.get_mouse_position()

	_mouse_positions.append(mouse_pos)
	_mouse_timestamps.append(now)

	while _mouse_timestamps.size() > 1 and (now - _mouse_timestamps[0]) > _mouse_window:
		_mouse_timestamps.pop_front()
		_mouse_positions.pop_front()

	if _mouse_positions.size() >= 2:
		var elapsed:float = now - _mouse_timestamps[0]
		mouse_displacement = _mouse_positions[0].distance_to(_mouse_positions[-1])
		mouse_speed = mouse_displacement / elapsed if elapsed > 0.0 else 0.0
	else:
		mouse_displacement = 0.0
		mouse_speed = 0.0

func _update_mic()->void:
	if audio_bus_id == -1:
		return
	_mic_volume = AudioServer.get_bus_peak_volume_right_db(audio_bus_id, 0)
	mic_level = _get_mic_level()

func _get_mic_level()->MIC_LEVEL:
	for level:MIC_LEVEL in MIC_LEVELS:
		if _mic_volume >= MIC_LEVELS[level]:
			print(_mic_volume, " >= ", MIC_LEVELS[level], " -> ", level)
			return level
	return MIC_LEVEL.SILENT

func _on_key_received(key_name:String)->void:
	last_key_time = Time.get_ticks_msec() / 1000.0
	if key_name == _last_key:
		return
	var now:float = Time.get_ticks_msec() / 1000.0
	_key_frame = key_window
	_key_timestamps.append(now)

	typing_rate = key_window * float(_key_timestamps.size())
	_last_key = key_name

func is_talking()->bool: return mic_level != MIC_LEVEL.SILENT
func is_writing()->bool: return typing_rate > key_window
func time_since_last_key()->float:
	return (Time.get_ticks_msec() / 1000.0) - last_key_time

func _to_string()->String:
	return "--UserInput--\n\tMicLevel: %s\n\tTypingRate: %.2f" % [MIC_LEVEL.keys()[mic_level], typing_rate]
