extends Node3D

var message_range = 3
var selected_item_index = 1
var in_menu = false
var message = ["Welcome Eyelander! What can I get you today."]

var player
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	for obj in $items.get_children():
		var mull_msg = obj.name
		message.append(mull_msg)

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))
	
	
func _process(delta):
	#print(in_menu)
	if global_position.distance_to(player.global_position) < message_range:
		if message:
			player.message_ui = message
		if player.message_index >= 1:
			in_menu = true
			player.look_at_override = $items.get_children()[player.message_index -1]
			var this_msg = message[player.message_index]
			var price = int(this_msg.split(" for ")[-1])
			var buy_text = this_msg.split(" for ")[0]
			print("spend: " + str(price))
			#player.message_ui[player.message_index] = buy_text
			
		else:
			in_menu = false
			player.look_at_override = null
	else:
		in_menu = false
		player.look_at_override = null
