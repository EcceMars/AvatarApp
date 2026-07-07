class_name MAIN
extends Node

enum Direction {
	FRONT,
	LEFT,
	LEFT_UP,
	UP,
	RIGHT_UP,
	RIGHT
	}

@export_category("Components")
@export var AUDIO_STREAM:AudioStreamPlayer
@export var AVATAR_ANCHOR:Node2D
@export var AVATAR_WINDOW:Window
@export var HANDLER_WINDOW:Window
@export var INPUT_SERVER:InputServer
@export var MACHINE:STATEMACHINE
@export var PASS_POLYGON:Polygon2D
@export var UI_WINDOW:Popup
@export var USER_INPUT:UserInput

@export_category("Model Parts")
@export var MAIN_SPRITE:Sprite2D
@export var MOUTH_SPRITE:MouthAnimation
@export var HAIR_SPRITE:Sprite2D
@export var EYES_SPRITE:EyeAnimation

@export_category("Configuration")
@export var BASE_SPRITE_SIZE:Vector2i = Vector2i(96, 96)
@export var MIN_SCALE:float = 5.0
@export var MAX_SCALE:float = 20.0
@export var STEP_SCALE:float = 0.5
@export var talk_buffer:float = 0.8
@export var writing_extra:float = 0.4
@export var point_velocity_threshold:float = 500.0
@export var point_min_displacement:float = 96.0
@export var point_revert_delay:float = 2.
@export_file_path var listener_path:String
@export var system_python:String = "/usr/bin/python3"
@export var alt_frequency_max:float = 6.0
@export var alt_frequency_min:float = 3.0
var alt_frequency:float = 6.0
var alt_frame:float = alt_frequency

const SKINS:Array[String] = ["casual", "strategy"]
const SKIN_PARTS:Array[String] = ["BASE", "EYES", "HAIR", "MOUTH"]

var mac:bool = false

var current_skin:String = "casual"

var current_scale:float = MIN_SCALE
var model_size:Vector2i = Vector2(BASE_SPRITE_SIZE) * current_scale
var _listener_pid:int = -1

var dragging:bool = false
var drag_offset:Vector2i = Vector2i.ZERO

var direction:Direction = Direction.FRONT

var _pointing_buffer:float = 0.0
var _writing_frame:float = 0.0
var is_pointing:bool = false
var is_writing:bool = false

func _ready()->void:
	mac = OS.get_name() == 'macOS'
	
	# Setup UserInput with mouth sprite and talk buffer
	USER_INPUT.setup(
		get_viewport(), 
		INPUT_SERVER, 
		AUDIO_STREAM,
		MOUTH_SPRITE,
		talk_buffer
	)
	
	# ROOT WINDOW
	get_window().mouse_passthrough = true
	get_window().mouse_passthrough_polygon = []
	get_window().borderless = true
	get_window().transparent = true
	
	_apply_skin(current_skin)
	_start_keyboard_listener()
	
	get_tree().auto_accept_quit = false
	
	model_size = Vector2(BASE_SPRITE_SIZE) * current_scale
	AVATAR_ANCHOR.scale = Vector2.ONE * current_scale
	
	_apply_scale(0.0)
	_place_windows()

func _get_listener_script()->String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(listener_path)
	return OS.get_executable_path().get_base_dir().path_join("keyboard_listener.py")

func _get_python_executable()->String:
	if OS.has_feature("windows"):
		return "python"
	return system_python

func _start_keyboard_listener()->void:
	var script:String = _get_listener_script()
	if not FileAccess.file_exists(script):
		print("Keyboard listener script not found at %s" % script)
		return
	_listener_pid = OS.create_process(_get_python_executable(), [script])

func _apply_scale(delta:float)->void:
	current_scale = clampf(current_scale + STEP_SCALE * sign(delta), MIN_SCALE, MAX_SCALE)
	
	var prev_size:Vector2i = model_size
	model_size = Vector2(BASE_SPRITE_SIZE) * current_scale
	
	AVATAR_ANCHOR.scale = Vector2.ONE * current_scale
	if mac:
		var x_off:int = abs(prev_size.x - model_size.x) / 2
		var y_off:int = abs(prev_size.y - model_size.y)
		AVATAR_WINDOW.position.y -= y_off * sign(delta)
		AVATAR_WINDOW.position.x -= x_off * sign(delta)
	HANDLER_WINDOW.size = Vector2(24, 8) * current_scale
	AVATAR_WINDOW.size = model_size
	_relocate_handler()
	_update_passthrough()

func _place_windows()->void:
	var id:int = 1 if DisplayServer.get_screen_count() > 1 else 0 # This is hardcoded
	var usable:Vector2i = DisplayServer.screen_get_size(id)
	var displacement:Vector2i = Vector2i(usable.x / 2, usable.y - model_size.y)
	AVATAR_WINDOW.position = displacement - Vector2i.RIGHT * (model_size / 2)
	
	if not mac:
		AVATAR_WINDOW.hide()
		HANDLER_WINDOW.hide()
		
		AVATAR_WINDOW.force_native = true
		HANDLER_WINDOW.force_native = true
	
	AVATAR_WINDOW.always_on_top = true
	HANDLER_WINDOW.always_on_top = true
	
	AVATAR_WINDOW.transparent = true
	HANDLER_WINDOW.transparent = true
	
	AVATAR_WINDOW.visible = true
	HANDLER_WINDOW.visible = true
	_relocate_handler()

func _physics_process(delta:float)->void:
	INPUT_SERVER.update()
	USER_INPUT.update(delta)  # This now handles mouth animation internally
	_pointing_update(delta)
	_writing_update(delta)
	
	alt_frame += delta
	if alt_frame > alt_frequency:
		alt_frame = 0.0
		alt_frequency = randf_range(alt_frequency_min, alt_frequency_max)
		MACHINE.alternate = !MACHINE.alternate

func _process(_delta:float)->void:
	if not dragging: return
	AVATAR_WINDOW.position = DisplayServer.mouse_get_position() - drag_offset
	_relocate_handler()

func get_point_dir()->Direction:
	var mouse_x:float = AVATAR_ANCHOR.get_global_mouse_position().x
	var mouse_y:float = AVATAR_ANCHOR.get_global_mouse_position().y
	
	var avatar_left:float = AVATAR_ANCHOR.global_position.x * 0.5 - model_size.x
	var avatar_right:float = AVATAR_ANCHOR.global_position.x * 0.5 + model_size.x
	var avatar_top:float = AVATAR_ANCHOR.global_position.y - model_size.y * 0.5
	
	if mouse_y < avatar_top:
		if mouse_x < avatar_left: return Direction.LEFT_UP
		if mouse_x > avatar_right: return Direction.RIGHT_UP
		return Direction.UP
	
	if mouse_x < avatar_left: return Direction.LEFT
	if mouse_x > avatar_right: return Direction.RIGHT
	
	return Direction.FRONT

func _pointing_update(delta:float)->void:
	direction = get_point_dir()
	if direction == Direction.FRONT:
		is_pointing = false
		_pointing_buffer = -1.0
		return
	var speed:float = USER_INPUT.mouse_speed
	var displacement:float = USER_INPUT.mouse_displacement

	if speed >= point_velocity_threshold and displacement >= point_min_displacement:
		if is_pointing:
			_pointing_buffer = point_revert_delay
		else:
			_pointing_buffer = point_revert_delay
			is_pointing = true
	else:
		if _pointing_buffer > 0.0:
			_pointing_buffer -= delta
			if _pointing_buffer <= 0.0:
				is_pointing = false

func _writing_update(delta:float)->void:
	if _writing_frame > 0.0:
		is_writing = true
		_writing_frame -= delta
		return
	is_writing = USER_INPUT.is_writing()
	if is_writing:
		_writing_frame = writing_extra

func _relocate_handler()->void:
	HANDLER_WINDOW.position.x = AVATAR_WINDOW.position.x + AVATAR_WINDOW.size.x / 2 - HANDLER_WINDOW.size.x / 2
	HANDLER_WINDOW.position.y = AVATAR_WINDOW.position.y + AVATAR_WINDOW.size.y - HANDLER_WINDOW.size.y * 3

func _update_passthrough()->void:
	if mac:
		AVATAR_WINDOW.mouse_passthrough_polygon = []
		return
	var new_poly:PackedVector2Array = PackedVector2Array()
	for i:int in PASS_POLYGON.polygon.size():
		var point:Vector2 = PASS_POLYGON.polygon[i]
		point *= current_scale
		new_poly.append(point)
	AVATAR_WINDOW.mouse_passthrough_polygon = new_poly

func _on_handler_gui_input(event:InputEvent)->void:
	if not event is InputEventMouseButton: return
	
	match(event.button_mask):
		MOUSE_BUTTON_LEFT:
			dragging = true
			drag_offset = DisplayServer.mouse_get_position() - AVATAR_WINDOW.position
		MOUSE_BUTTON_RIGHT:
			_show_ui()
		8:
			_apply_scale(1)
			return
		16:
			_apply_scale(-1)
			return
	if event.is_released():
		dragging = false

func _show_ui()->void:
	if UI_WINDOW.visible:
		UI_WINDOW.hide()
		return
	UI_WINDOW.force_native = true
	UI_WINDOW.visible = true
	UI_WINDOW.transparent = true
	UI_WINDOW.transparent_bg = true
	UI_WINDOW.size = Vector2i.ONE * 50 * current_scale
	UI_WINDOW.position = AVATAR_WINDOW.position + Vector2i(AVATAR_WINDOW.size.x - UI_WINDOW.size.x, - model_size.y) / 2

func _apply_skin(skin_name:String)->void:
	if not SKINS.has(skin_name):
		push_warning("Unknown skin: %s" % skin_name)
		return
	var textures:Dictionary[String, Texture2D] = _load_skin(skin_name)
	MAIN_SPRITE.texture  = textures["BASE"]
	EYES_SPRITE.texture  = textures["EYES"]
	HAIR_SPRITE.texture  = textures["HAIR"]
	MOUTH_SPRITE.texture = textures["MOUTH"]
	current_skin = skin_name
	
	UI_WINDOW.hide()

func _load_skin(skin_name:String)->Dictionary[String, Texture2D]:
	var textures:Dictionary[String, Texture2D] = {}
	for part in SKIN_PARTS:
		var path:String = "res://assets/%s/%s.png" % [skin_name, part]
		textures[part] = load(path)
	return textures

func _quit()->void:
	get_tree().quit()

func _notification(what:int)->void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _listener_pid != -1:
			OS.kill(_listener_pid)
		get_tree().quit()
