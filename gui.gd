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
			$pause_menu.add_child(new_slot)
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
			var in_use = slot_data["equipped"]
			if in_use:
				this_slot.modulate = Color(1,1,1)
			else:
				this_slot.modulate = Color(.2,.2,.2)
			this_slot_icon.texture = slot_data["icon"]
			
			#this_slot.add_child(slot_data["icon"])
			#print("need to render: " + str(slot_data))



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
