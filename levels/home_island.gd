extends Node3D

@onready var city_center_npc = $NPCs/Briska
var city_center_npc_msg = ["[center][font_size=30]Have you noticed the water has been [b][color=red]rising[/color][/b] a lot recently? [/font_size][/center]",
"[center][font_size=30]I hope it stops soon :( [/font_size][/center]"]

var bg_music = "res://import/CC-BY Kevin MacLeod/Kevin MacLeod - Nu Flute_edit.wav"
var fight_music = "res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav"
# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Setup City Center NPC
	city_center_npc.message = city_center_npc_msg
	
	var skin = city_center_npc.find_child("Briska").get_active_material(0)
	skin.albedo_color = Color("#aaeeff")
	city_center_npc.find_child("Briska").set_surface_override_material(0, skin)
	
	var shirt = StandardMaterial3D.new()
	shirt.albedo_color = Color("#000000")
	city_center_npc.find_child("Briska").set_surface_override_material(1, shirt)
	
	#city_center_npc.find_child("Armature").scale.y = .6


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
