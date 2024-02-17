extends Node3D

var message = null
var message_range = 3

var player

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	#Hid unneded meshes
	for mesh in $Armature/Skeleton3D.get_children():
		if mesh.name != name:
			mesh.visible = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(player.global_position) < message_range:
		if message:
			player.message_ui = message
