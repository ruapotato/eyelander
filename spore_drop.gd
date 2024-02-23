extends Node3D
var inventory_name = "spore"
var player
var range = 1

@onready var animation_tree = find_child("mesh").find_child("AnimationTree")

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	

func _process(delta):
	if global_position.distance_to(player.global_position) < range:
		print("Yo " + inventory_name)
		queue_free()
		
