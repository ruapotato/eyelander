extends Sprite2D

var player
var hovred = false
var selected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()


func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if selected:
		$icon.global_position = get_global_mouse_position()
		if not Input.is_action_pressed("swipe"):
			selected = false
			player.gui.dragging = false
			player.gui.swap_slots(self, player.gui.drag_hover)
			print("drop")
			$icon.position = Vector2(0,0)


func _on_static_body_2d_mouse_entered():
	print(name)
	hovred = true
	
	if player.gui.dragging:
		player.gui.drag_hover = self
		#print("Drug to " + name)


func _on_static_body_2d_mouse_exited():
	hovred = false



func _on_static_body_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if hovred:
				if not player.gui.dragging:
					player.gui.dragging = true
					selected = true
					print(event)
