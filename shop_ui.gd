extends Node3D

var message_range = 3
var selected_item_index = 1
var in_menu = false
var message = ["Welcome Eyelander! What can I get you today."]
var message_options = []
var item_data = [{"count":1,"equipped":false,"handed":"left","icon":"res://import/CC0 by Henrique Lazarini, 7Soul1/edits/Shield.png","max_count":1,"name":"shield_l1","scene":"res://shield.tscn"},
	{"count":1,"equipped":false,"handed":"right","icon":"res://import/CC0 by Henrique Lazarini, 7Soul1/edits/WWW_killer.png","max_count":1,"name":"sword_l1","scene":"res://sword.tscn"}]

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
	
func has_slot():
	return player.get_next_inventory_slot()

func has_crystals(needed):
	if player.inventory["crystals"] >= needed:
		return true
	return false

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
			if has_crystals(price) and has_slot():
				message_options = ["Buy", "Quit"]
			else:
				message_options = ["Quit"]
			player.message_options = message_options
			
			
			if message_options:
				if Input.is_action_just_pressed("menu_select"):
					var action = message_options[player.message_option_index -1]
					if action == "Buy":
						var slot_index = has_slot()
						var new_item = item_data[player.message_index -1]
						player.items[slot_index[0]][slot_index[1]] = new_item
						player.inventory["crystals"] -= price
						player.gui.draw_items(player.items)
					if action == "Quit":
						player.message_index = -1
						player.message_option_index = 1
						player.message_box.visible = false
						player.message_bg.visible = false
					print(action)
			#print("spend: " + str(price))
			#player.message_ui[player.message_index] = buy_text
			
		else:
			in_menu = false
			player.look_at_override = null
			player.message_options = null
	else:
		in_menu = false
		player.look_at_override = null
		player.message_options = null
