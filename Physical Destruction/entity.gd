extends CharacterBody3D

class_name Entity

@onready var nav_ag: NavigationAgent3D = $NavigationAgent3D
@export var speed = 1.0
const movement_smoothnes = 1

@export var health = 50.0
@export var interact_range = 10.0
@export var damage = 0.0
@export var damage_rad = 0.7

enum ENTITY_TYPE{
	NPC, HOSTILE, SLEEPING,
}
var ENTTYPE_ATTRS: Dictionary = {
	ENTITY_TYPE.NPC: {
		"target": func():
			nav_ag.target_position = Vector3(randf_range(-interact_range, interact_range), 0, randf_range(
				-interact_range, interact_range)),
	},
	ENTITY_TYPE.SLEEPING: {
		"target": func():,
	},
	ENTITY_TYPE.HOSTILE: {
		"target": func():
			var closest_pl_pos: Vector3 = Vector3.INF
			for pl in get_tree().get_nodes_in_group("Player"):
				if (global_transform.origin - pl.global_transform.origin).length() < closest_pl_pos.length():
					closest_pl_pos = pl.global_transform.origin
			nav_ag.target_position = closest_pl_pos,
	},
}
@export var type = ENTITY_TYPE.NPC

func _ready():
	$DamageRange/CollisionShape3D.shape.radius = damage_rad

func _process(delta):
	if health <= 0: queue_free()
	
	if type == ENTITY_TYPE.HOSTILE:
		ENTTYPE_ATTRS[type]["target"].call()

	if type != ENTITY_TYPE.SLEEPING:
		var cur_loc = global_transform.origin
		var next_loc = nav_ag.get_next_path_position()
		if is_on_floor():
			var new_vel = (next_loc - cur_loc).normalized() * speed
			velocity = velocity.move_toward(new_vel, movement_smoothnes)
		
	move_and_slide()
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta

func _on_navigation_agent_3d_target_reached():
	ENTTYPE_ATTRS[type]["target"].call()

func _on_damage_range_body_entered(body):
	if body.is_in_group("Player"):
		body.health -= damage
		print(body.health)

func _on_col_check_body_entered(body):
	if type == ENTITY_TYPE.NPC:
		ENTTYPE_ATTRS[type]["target"].call()
