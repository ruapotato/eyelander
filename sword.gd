extends RigidBody3D

var init_pos
var init_rot
# Called when the node enters the scene tree for the first time.
func _ready():
	init_pos = position
	init_rot = rotation
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	axis_lock_angular_y = true
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	add_collision_exception_with(get_parent())
	add_collision_exception_with(get_parent().find_child("shild"))

func _integrate_forces(state):
	if rotation != init_rot:
		if get_contact_count() == 0:
			#rotation = lerp(rotation, init_rot, .15)
			pass
	if position != init_pos:
		if get_contact_count() == 0:
			pass
			#position = lerp(position, init_pos, .15)
			#apply_impulse()
			#position = init_pos
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
