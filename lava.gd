extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for body in get_overlapping_bodies():
		if body.name == "boss_1":
			body.rage_counter = 0
			body.damage_todo += delta * 500
		if body.name == "player":
			body.damage_todo += (delta * 500) / get_parent().get_parent().get_parent().hardness
