extends RigidBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
var mouse_sensitivity = .0035
var speed = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	set_lock_rotation_enabled(true)


func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)


func _physics_process(delta):
	var wanted_dir = Vector3(0,0,0)
	if Input.is_action_pressed("forward"):
		wanted_dir.z = -speed
	if Input.is_action_pressed("backward"):
		wanted_dir.z = speed
	
	var local = to_local(global_position)
	var local_target = local + wanted_dir

	var global_direction = -global_transform.basis.x * speed
	var player_pushback = global_transform.basis.x * .04
	apply_impulse(local_target * speed * delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
