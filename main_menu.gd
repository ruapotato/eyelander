extends Node2D

@onready var game = preload("res://world.tscn")
var new_game = null
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.show()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	if new_game != null:
		new_game.queue_free()
	new_game = game.instantiate()
	self.hide()
	add_child(new_game)
