extends CharacterBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
@onready var mesh = $mesh
var mouse_sensitivity = .0035
var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 4.5
var SPEED = 5.0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (piv.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	#-global_transform.basis.z * wanted_dir 
	#linear_velocity += -piv.global_transform.basis.x * wanted_dir 
	#apply_impulse(wanted_dir, wanted_dir * 10)
	#apply_impulse(global_direction * speed * delta )
	#linear_velocity = global_direction
	#linear_velocity += wanted_dir
	#var local = to_local(global_position)
	#var local_target = local + wanted_dir

	#var global_direction = -global_transform.basis.x * speed
	#var player_pushback = global_transform.basis.x * .04
	#apply_impulse(local_target * speed * delta)
	#rotation.y = lerp_angle(rotation.y, atan2(-linear_velocity.x, -linear_velocity.z), .1)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
