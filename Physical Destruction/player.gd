extends RigidBody3D

class_name Player

var velocity: Vector3
var on_ground = false
const SPEED = 900.0
const JUMP_FORCE = 5.0
const SLOWER_FACTOR = 9.0
const SPRINTING_SPEED = 1.5
@export var senst = 50
const SENST_MULT = 0.0001
@export var pitch_lock = 80
@onready var orient = $Orientation
@onready var cam = $Orientation/Camera3D

@export var bobbing_speed = 0.4
@export var bobbing_amplitude = 0.15
var bob_timer = 0.0
@onready var initl_cam_y = $Orientation/Camera3D.position.y
var stop_bobbing = true

var sprinting = false

@onready var pickup_pos = $Orientation/Camera3D/PickupPos
var cur_pickable: Pickable = null

var initl_lin_damp = linear_damp
@export var health = 100.0

@onready var front_check = $Orientation/Camera3D/FrontCheck

@export var resize_amount = 5
@export var gravity_modifier_amount = 1

@export var throw_force_addition = 50
var throw_force = 0.0

func Pickup_pickable(pickable: Pickable):
	pickable.gravity_scale = 0.0
	pickable.get_node("CollisionShape3D").disabled = true
	cur_pickable = pickable
	pickable.linear_velocity = Vector3.ZERO
	pickable.angular_velocity = Vector3.ZERO
	pickable.reparent(self)
	
func Drop_pickable(pickable: Pickable):
	pickable.gravity_scale = pickable.initl_grav_scl
	pickable.get_node("CollisionShape3D").disabled = false
	cur_pickable = null
	pickable.linear_velocity = Vector3.ZERO
	pickable.angular_velocity = Vector3.ZERO
	pickable.reparent(pickable.initl_parent)
	print("well vello tello")

func Freeze(what_to_freeze):
	var static_wtf = StaticBody3D.new()
	for c in what_to_freeze.get_children():
		static_wtf.add_child(c.duplicate())
	get_parent().add_child(static_wtf)
	static_wtf.global_position = what_to_freeze.global_position
	static_wtf.global_rotation = what_to_freeze.global_rotation
	what_to_freeze.queue_free()

func Resize_pickable(pickable: Pickable, mult: float):
	for c in pickable.get_children():
		c.scale += Vector3.ONE * mult * resize_amount

func Modify_pickable_gravscl(pickable: Pickable, mult: float):
	pickable.initl_grav_scl += mult * gravity_modifier_amount
	
func Throw_pickable(pickable: Pickable, force: Vector3):
	Drop_pickable(pickable)
	pickable.apply_central_impulse(force)

func _unhandled_input(event):
	# looking around
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orient.rotate_y(-event.relative.x * senst * SENST_MULT)
		cam.rotate_x(-event.relative.y * senst * SENST_MULT)
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -pitch_lock, pitch_lock)
	# other
	if event is InputEventKey and event.is_action_pressed("sprint_toggle"):
		print(sprinting)
		sprinting = not sprinting
	if event is InputEventKey and ((front_check.is_colliding() and front_check.get_collider() is Pickable) or cur_pickable) and event.is_action_pressed("pickup_or_drop"):
		if not cur_pickable: Pickup_pickable(front_check.get_collider())
		else: Drop_pickable(cur_pickable)
	
	if event is InputEventKey and event.is_action_pressed("freeze") and front_check.is_colliding():
		Freeze(front_check.get_collider())

	if event is InputEventKey and event.is_action_released("throw") and cur_pickable:
		Throw_pickable(cur_pickable, (cur_pickable.position - cam.position) * throw_force)
		throw_force = 0.0

func _physics_process(delta):
	if $GroundCheck.is_colliding() and $GroundCheck.get_collider().is_in_group("Ground"):
		on_ground = true
	else:
		on_ground = false

	linear_damp = initl_lin_damp if on_ground else 0.0
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and on_ground:
		apply_central_impulse(JUMP_FORCE * mass * Vector3.UP)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (orient.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var sprint_val = SPRINTING_SPEED if sprinting else 1
	if direction:
		velocity.x = direction.x * SPEED * sprint_val * mass * delta
		velocity.z = direction.z * SPEED * sprint_val * mass * delta
		# bobbing
		if on_ground:
			cam.position.y = initl_cam_y + sin(bob_timer * bobbing_speed/100 * sprint_val) * bobbing_amplitude
			bob_timer += delta * 1000
			stop_bobbing = true
	else:
		var slowing_delta = SPEED * delta * SLOWER_FACTOR * sprint_val * mass
		velocity.x = move_toward(velocity.x, 0, slowing_delta)
		velocity.z = move_toward(velocity.z, 0, slowing_delta)
		# bobbing
		if stop_bobbing:
			cam.position.y = initl_cam_y
			bob_timer = 0.0
			stop_bobbing = false

	apply_force(velocity, global_transform.origin)
	
func _process(delta):
	if health <= 0.0: queue_free()
	
	if Input.is_action_pressed("throw") and cur_pickable:
		throw_force += throw_force_addition * delta
	
	if cur_pickable:
		$PickableProps.visible = true
		$PickableProps/GravityScale.text = "Gravity Scale: " + str(cur_pickable.initl_grav_scl)
		
		if Input.is_action_pressed("grow"):
			Resize_pickable(cur_pickable, delta)
		if Input.is_action_pressed("shrink"):
			Resize_pickable(cur_pickable, -delta)
		
		if Input.is_action_pressed("add_gravity"):
			Modify_pickable_gravscl(cur_pickable, delta)
		if Input.is_action_pressed("take_gravity"):
			Modify_pickable_gravscl(cur_pickable, -delta)
	else:
		$PickableProps.visible = false
