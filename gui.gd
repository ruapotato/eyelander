extends Node2D

@onready var player = get_parent()
var main_slots = 5
var main_slot_pos = [1500,57]
var buffer = 15
var size = 75
var item_slot = preload("res://item_bg.tscn")
var life_icon = preload("res://life_icon.tscn")

var backpack_slots_c = 10
var backpack_slots_r = 5
var backpack_slot_pos = [500,400]
var backpack_slots = []

var life_buffer = 1
var gui_life_slots_c = 8
var gui_life_slots_r = 2
var gui_life_slot_pos = [110,50]
var rendered_items = []
var top_slots = []

var dragging = null
var drag_hover = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Setup main slots
	var pos = main_slot_pos[0]
	for i in range(0, main_slots):
		var my_pos = pos + (i * size) + (i * buffer)
		var new_slot = item_slot.instantiate()
		new_slot.name = "item_bg_" + str(i)
		new_slot.position = Vector2(my_pos, main_slot_pos[1])
		top_slots.append(new_slot)
		add_child(new_slot)
		
	# Setup backpack slots

	for c in range(0, backpack_slots_c):
		var col = []
		for r in range(0, backpack_slots_r):
			var my_pos_c = backpack_slot_pos[0] + (c * size) + (c * buffer)
			var my_pos_r = backpack_slot_pos[1] + (r * size) + (r * buffer)
			var new_slot = item_slot.instantiate()
			new_slot.name = "item_backpack_bg_" + str(c) + "X" + str(r)
			new_slot.position = Vector2(my_pos_c, my_pos_r)
			col.append(new_slot)
			$backpack_slots.add_child(new_slot)
		backpack_slots.append(col)

	# Setup life slots
	var index = 0
	for r in range(0, gui_life_slots_r):
		for c in range(0, gui_life_slots_c):
			index += 1
			var my_pos_c = gui_life_slot_pos[0] + (c * size) + (c * life_buffer)
			var my_pos_r = gui_life_slot_pos[1] + (r * size) + (r * life_buffer)
			var new_slot = life_icon.instantiate()
			new_slot.name = "LIFE_" + str(index)
			print(new_slot.name)
			new_slot.position = Vector2(my_pos_c, my_pos_r)
			add_child(new_slot)


func get_slot_data(slot):
	var data_index = [0,0]
	if "item_bg" in slot.name:
		data_index[1] = int(slot.name.split("_")[-1])
	elif "item_backpack_bg" in slot.name:
		var end_bit = slot.name.split("_")[-1].split("X")
		data_index[0] = int(end_bit[0]) 
		data_index[1] = int(end_bit[1])
	var data = player.items[data_index[0]][data_index[1]]
	print("Data: " + str(data_index))
	if data == {}:
		return(player.blank_item)
	
	return(data)


func set_slot_data(slot, data):
	var data_index = [0,0]
	if "item_bg" in slot.name:
		data_index[1] = int(slot.name.split("_")[-1])
	elif "item_backpack_bg" in slot.name:
		var end_bit = slot.name.split("_")[-1].split("X")
		data_index[0] = int(end_bit[0])
		data_index[1] = int(end_bit[1])
	player.items[data_index[0]][data_index[1]] = data


func swap_slots(what_slot, where_slot):
	var what_data = get_slot_data(what_slot)
	var where_data = get_slot_data(where_slot)
	#print("moving: " + str(what_data))
	#print(what_slot)
	#print("To: " + str(where_data))
	#print(where_slot)
	#print(player.items)
	set_slot_data(where_slot, what_data)
	set_slot_data(what_slot, where_data)
	
	#print(player.items)
	draw_items(player.items)
	#print(what_slot)
	#print(where_slot)

func draw_items(items):
	print("Drawing ")
	print(items)
	
	#Main slots
	for i in range(0, main_slots):
		if items[0][i]:
			var slot_data = items[0][i]
			var slot_name = "item_bg_" + str(i)
			var this_slot = top_slots[i]
			var this_slot_icon = this_slot.find_child("icon")
			print(slot_data)
			var in_use = slot_data["equipped"]
			if in_use:
				this_slot.modulate = Color(1,1,1)
			else:
				this_slot.modulate = Color(.2,.2,.2)
			if "icon" in slot_data:
				this_slot_icon.texture = load(slot_data["icon"])
			else:
				this_slot_icon.texture = null
			
			#this_slot.add_child(slot_data["icon"])
			#print("need to render: " + str(slot_data))
	
	# backpack slots
	for r in range(0, backpack_slots_r):
		for c in range(0, backpack_slots_c):
			var slot_data = items[r + 1][c] 
			if slot_data == {}:
				continue
			var slot_name = "item_backpack_bg_" + str(c) + "X" + str(r)
			var this_slot = backpack_slots[r + 1][c]
			var this_slot_icon = this_slot.find_child("icon")
			#print(slot_data)
			var in_use = slot_data["equipped"]
			if in_use:
				this_slot.modulate = Color(1,1,1)
			else:
				this_slot.modulate = Color(.2,.2,.2)
			if "icon" in slot_data:
				this_slot_icon.texture = load(slot_data["icon"])
			else:
				this_slot_icon.texture = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if player.items != rendered_items:
	#	print("Update items!!!!!")
	#	draw_items(player.items)
	#	rendered_items = player.items


#if $compost.value < 33:
#	$compost.theme_override_styles.fill.bg_color = Color(1,0,0)
#else:
#	$compost.get_active_material(0)


func _on_compost_value_changed(value):
	pass
	#print($compost.add_theme_stylebox_override())
	#add_theme_stylebox_override ( "theme_override_styles/fill", load("res://MyStyleBox.tres") )
	#print($compost.)


func _on_button_pressed():
	for body in get_parent().get_children():
		body.queue_free()
	get_tree().reload_current_scene()
