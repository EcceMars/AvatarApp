class_name EyeAnimation
extends Sprite2D

var idle_frame:int = 2
var blinking:bool = false

func _blink(base:int = 0)->void:
	idle_frame = base
	if frame == base:
		var rand_n:float = randf()
		blinking = rand_n > 0.8
	
	if not blinking:
		frame = idle_frame
