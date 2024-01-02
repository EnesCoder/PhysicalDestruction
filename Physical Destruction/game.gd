extends Node3D

func _unhandled_input(event):
	if event.is_action_pressed("focus"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready():
	for ent in get_tree().get_nodes_in_group("Entity"):
		ent.ENTTYPE_ATTRS[ent.type]["target"].call()
