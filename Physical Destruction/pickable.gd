extends RigidBody3D

class_name Pickable

var initl_grav_scl = gravity_scale
@onready var initl_parent = get_parent()

func _process(_delta):
	if get_parent().is_in_group("Player"):
		global_position = get_parent().pickup_pos.global_position
