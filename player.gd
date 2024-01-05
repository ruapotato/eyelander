extends RigidBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
var mouse_sensitivity = .0035
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)


func _physics_process(delta):
	if Input.is_action_pressed("forward"):
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
