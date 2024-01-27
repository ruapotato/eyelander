extends Node2D

@onready var game = preload("res://world.tscn")
@onready var hardness_menu = $hardness
var new_game = null
var game_started = false
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	print(hardness_menu.value)


func start_game(made_trade):
	if not game_started:
		if new_game != null:
			new_game.queue_free()
		new_game = game.instantiate()
		new_game.hardness = hardness_menu.value/100
		new_game.made_trade = made_trade
		self.hide()
		add_child(new_game)
		game_started = true

func _on_exchange_button_down():
	start_game(true)


func _on_no_way_button_down():
	start_game(false)
