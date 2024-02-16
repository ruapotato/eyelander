extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


func _on_area_3d_body_entered(body):
	if body.name == "player":
		var where_name = name.split("~")[0]
		var where = load("res://" + where_name + ".tscn")
		var spawn_name = name.split("~")[1]
		get_player().needs_to_load = [where, spawn_name]
		
