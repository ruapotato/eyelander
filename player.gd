extends CharacterBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
@onready var mesh = $mesh
@onready var sword = $sword
@onready var shild = $shild
@onready var camera = $piv/SpringArm3D/Camera3D
var mouse_sensitivity = .0035
var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 4.5
var SPEED = 5.0
var sword_hold_angle = 315
var swipping = false
var swipe_speed = .35
var swipe_counter = 0
#var swipe_start_angle = 180
#var swipe_end_angle = 30
var swipe_stage = 1
var swipe_angles = {1: [180, 0], 2: [0,180],}

var shilding = false
var shild_hold_angle = 65
var shilding_angle = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		#rotate_x(event.relative.y * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
		#rotation.x = clamp(rotation.x, -PI/2, PI/2)
		
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		
	if Input.is_action_just_pressed("swipe"):
		swipping = true
		swipe_counter = swipe_speed
	
	
	if Input.is_action_just_pressed("shild"):
		shilding = true
	if Input.is_action_just_released("shild"):
		shilding = false
	
	#Update sowrd
	#var swipping = false
	#var swipe_speed = 1
	#var swipe_start_angle = 30
	#var swipe_end_angle = 120

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

	
	if shilding:
		# Set shilding pos
		shild.rotation_degrees.y = lerp(shild.rotation_degrees.y, shilding_angle + piv.rotation_degrees.y, .2)
		# Set camera 
		#shild.rotation_degrees.x = spring_arm.rotation_degrees.x
		# Set sword pos
		sword.rotation_degrees.y = piv.rotation_degrees.y - 200
	if not shilding:
		shild.rotation_degrees.y = shild_hold_angle + piv.rotation_degrees.y
	
	if swipping and not shilding:
		var swipe_start_angle = swipe_angles[swipe_stage][0]
		var swipe_end_angle =   swipe_angles[swipe_stage][1]
		#print(swipe_counter)
		swipe_counter -= delta
		if swipe_counter <= 0:
			swipe_counter = 0
			swipping = false
		else:
			var angle_amount = swipe_counter/swipe_speed
			var total_angles = swipe_end_angle - swipe_start_angle
			var angle = (total_angles * angle_amount) + swipe_start_angle
			#print(angle)
			sword.rotation_degrees.y = angle + piv.rotation_degrees.y + sword_hold_angle
	if not swipping and not shilding:
		#sword.rotation.y = lerp_angle(sword.rotation.y, atan2(-direction.x, -direction.z), .2)
		if not Input.is_action_pressed("swipe"):
			sword.rotation.y = piv.rotation.y + deg_to_rad(sword_hold_angle) 
		else:
			swipe_stage += 1
			#print(swipe_stage)
			if swipe_stage > len(swipe_angles):
				swipe_stage = 1
			swipping = true
			swipe_counter = swipe_speed
		#print(sword.rotation.y)
	move_and_slide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
