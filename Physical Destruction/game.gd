extends Node3D

func _ready():
	for ent in get_tree().get_nodes_in_group("Entity"):
		ent.ENTTYPE_ATTRS[ent.type]["target"].call()
