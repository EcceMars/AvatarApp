class_name MouthAnimation
extends Sprite2D

var _base_:int = 2
var talking:bool = false

func talk(base:int = 0)->void:
	_base_ = base
	if talking: return
	
	frame = _base_
