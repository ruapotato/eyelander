extends RigidBody3D
@onready var player = get_parent()
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
	add_collision_exception_with(get_parent().find_child("sword"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.left_hand_bone:
		global_position = player.left_hand_bone.global_position
		global_rotation = player.left_hand_bone.global_rotation
