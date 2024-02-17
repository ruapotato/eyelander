extends Node3D

@onready var city_center_npc = $NPCs/Briska
var city_center_npc_msg = ["[center][font_size=30]Have you noticed the water has been [b][color=red]rising[/color][/b] a lot recently? [/font_size][/center]",
"[center][font_size=30]I hope it stops soon :( [/font_size][/center]"]
# Called when the node enters the scene tree for the first time.
func _ready():
	city_center_npc.message = city_center_npc_msg
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
