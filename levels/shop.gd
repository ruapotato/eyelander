extends Node3D

@onready var shop_keep = $NPCs/island_male_1
var shop_keep_msg = ["[center][font_size=30]Have you noticed the water has been [b][color=red]rising[/color][/b] a lot recently? [/font_size][/center]",
"[center][font_size=30]I hope it stops soon :( [/font_size][/center]"]
# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Setup City Center NPC
	shop_keep.message = shop_keep_msg
	
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color("#aaeeff")
	shop_keep.find_child("island_male_1").set_surface_override_material(0, skin)
	
	var shirt = StandardMaterial3D.new()
	shirt.albedo_color = Color("#000000")
	shop_keep.find_child("island_male_1").set_surface_override_material(1, shirt)
	
	#shop_keep.find_child("Armature").scale.y = .6


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
