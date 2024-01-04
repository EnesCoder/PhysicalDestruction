extends RigidBody3D

class_name Pickable

var initl_grav_scl = gravity_scale
@onready var initl_parent = get_parent()
var rotation_offset = Vector3.ZERO
@export var rotation_speed = 5

func _process(delta):
	if get_parent().is_in_group("Player"):
		global_position = get_parent().pickup_pos.global_position
		global_rotation = get_parent().cam.global_rotation + rotation_offset
	
		var rot = rotation_speed * delta
		if Input.is_key_label_pressed(KEY_R):
			rotation_offset.y -= rot
		if Input.is_key_label_pressed(KEY_T):
			rotation_offset.y += rot
		if Input.is_action_pressed("ui_left"):
			rotation_offset.x += rot
		if Input.is_action_pressed("ui_right"):
			rotation_offset.x -= rot
		if Input.is_action_pressed("ui_down"):
			rotation_offset.z += rot
		if Input.is_action_pressed("ui_up"):
			rotation_offset.z -= rot
	else:
		rotation_offset = Vector3.ZERO
