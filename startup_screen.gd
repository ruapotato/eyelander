extends Node2D

@onready var game = preload("res://world.tscn")
var new_game = null
var time_to_show = 10
var game_started = false
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not game_started:
		if Input.is_anything_pressed():
			time_to_show = 0
		time_to_show -= delta
		if time_to_show < 0:
			if new_game != null:
				new_game.queue_free()
			new_game = game.instantiate()
			self.hide()
			add_child(new_game)
			game_started = true


