extends RigidBody3D

class_name Player

var velocity: Vector3
var on_ground = false
const SPEED = 20.0
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

@onready var pickuper = $Orientation/Camera3D/Pickuper
@onready var pickup_pos = $Orientation/Camera3D/PickupPos
var cur_pickable: Pickable = null

var initl_lin_damp = linear_damp

func Pickup_pickable(pickable: Pickable):
	pickable.gravity_scale = 0.0
	cur_pickable = pickable
	pickable.reparent(self)
	
func Drop_pickable(pickable: Pickable):
	pickable.gravity_scale = pickable.initl_grav_scl
	cur_pickable = null
	pickable.reparent(pickable.initl_parent)

func _unhandled_input(event):
	# mouse and looking around
	if event.is_action_pressed("focus"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orient.rotate_y(-event.relative.x * senst * SENST_MULT)
		cam.rotate_x(-event.relative.y * senst * SENST_MULT)
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -pitch_lock, pitch_lock)
	# other
	if event is InputEventKey and event.is_action_pressed("sprint_toggle"):
		print(sprinting)
		sprinting = not sprinting
	if event is InputEventKey and pickuper.is_colliding() and event.is_action_pressed("pickup_or_drop"):
		if not cur_pickable: Pickup_pickable(pickuper.get_collider())
		else: Drop_pickable(pickuper.get_collider())

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
		velocity.x = direction.x * SPEED * sprint_val * mass
		velocity.z = direction.z * SPEED * sprint_val * mass
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
