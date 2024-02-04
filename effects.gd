extends Node3D


func get_effect_amount():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player").effects_effector)

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if "particles" in child.name:
			child.amount = (child.amount * get_effect_amount()) + 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
