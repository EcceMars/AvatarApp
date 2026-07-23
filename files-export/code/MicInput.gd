class_name MicInput
extends RefCounted

var mouth:MouthAnimation
var talk_buffer_length:float = 0.8

var is_talking:bool = false

var _buffer:float = 0.0

func setup(mouth_node:MouthAnimation, buffer_length:float)->void:
	mouth = mouth_node
	talk_buffer_length = buffer_length

func update(delta:float, mic_active:bool)->void:
	if mic_active:
		_buffer = talk_buffer_length
		is_talking = true
	else:
		if _buffer > 0.0:
			_buffer -= delta
		is_talking = _buffer > 0.0

	mouth.talking = is_talking
