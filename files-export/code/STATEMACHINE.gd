class_name STATEMACHINE
extends Node

@export var main:MAIN
@export var animtree:AnimationTree
@export var debugger:Label

const Direction = main.Direction

var alternate:bool = false
var pointing:bool:
	get: return main.is_pointing
var point_direction:Direction:
	get:
		return main.direction
var talking:bool:
	get: return main.USER_INPUT._is_talking
var writing:bool:
	get: return main.is_writing
	
var point_state_done:bool = true

var playback:AnimationNodeStateMachinePlayback
func _ready()->void:
	playback = animtree.get("parameters/playback")
var last_node:String = ""
func _process(_delta:float)->void:
	var current_node:String = playback.get_current_node()
	if last_node != current_node:
		last_node = current_node
		debugger.text = last_node
		
func get_direction()->Direction: return point_direction
func get_keyboard_idle_length()->float: return main.USER_INPUT.time_since_last_key()
