extends Node3D

@onready var static_body = $StaticBody3D
# Called when the node enters the scene tree for the first time.
func _ready():
	var collision_shapes = []
	for child in get_children():
		if child is MeshInstance3D:
			child.create_trimesh_collision()
			collision_shapes.append(child.get_child(0))
			static_body.add_child(collision_shapes[-1])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
