extends Node3D
var player
var range = 1
var snap_countdown = .2
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(player.global_position) < range:
		if not animation_tree.get("parameters/bite/active"):
			animation_tree.set("parameters/bite/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			snap_countdown = .2
		else:
			snap_countdown -= delta
		if snap_countdown < 0:
			print("Yo Stuck")
			player.velocity = Vector3(0,0,0)
			player.new_speed = Vector3(0,0,0)
			player.dazzed = .05
