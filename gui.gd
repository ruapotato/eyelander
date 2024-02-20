extends Node2D

var main_slots = 5
var main_slot_pos = [1128,57]
var buffer = 15
var size = 75
var item_slot = preload("res://item_bg.tscn")

var backpack_slots_c = 10
var backpack_slots_r = 5
var backpack_slot_pos = [500,400]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Setup main slots
	var pos = main_slot_pos[0]
	for i in range(0, main_slots):
		var my_pos = pos + (i * size) + (i * buffer)
		var new_slot = item_slot.instantiate()
		new_slot.name = "item_bg_" + str(i)
		new_slot.position = Vector2(my_pos, main_slot_pos[1])
		add_child(new_slot)
		
	# Setup backpack slots
	for c in range(0, backpack_slots_c):
		for r in range(0, backpack_slots_r):
			var my_pos_c = backpack_slot_pos[0] + (c * size) + (c * buffer)
			var my_pos_r = backpack_slot_pos[1] + (r * size) + (r * buffer)
			var new_slot = item_slot.instantiate()
			new_slot.name = "item_backpack_bg_" + str(c) + "X" + str(r)
			new_slot.position = Vector2(my_pos_c, my_pos_r)
			$pause_menu.add_child(new_slot)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
