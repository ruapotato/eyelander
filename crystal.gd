extends Area3D

var value = null
var message_range = 3
var bob_speed = .7
var timer = 0
var player
var init_pos
var collected = false
var collected_animation = .5

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	init_pos = global_position
	player = get_player()
	value = int(name.split("_")[0])
	#print(value)
	var color
	if value >= 200:
		color = Color("#6600cc")
	elif value >= 150:
		color = Color("#000000")
	elif value >= 100:
		color = Color("#AAAAAA")
	elif value >= 50:
		color = Color("#ff4d94")
	elif value >= 20:
		color = Color("#cc0000")
	elif value >= 10:
		color = Color("#ffff00")
	elif value >= 5:
		color = Color("#008000")
	else:
		color = Color("#ff8000")
	
	var color_material = StandardMaterial3D.new()
	color_material.albedo_color = color
	color_material.metallic = .75
	color_material.roughness = .07
	color_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	color_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	color_material.cull_mode = BaseMaterial3D.CULL_FRONT
	#color_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	#color_material.no_depth_test = true
	
	var outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(0,0,0)
	outline_material.metallic = .75
	outline_material.roughness = .07
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	#outline_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_material.grow = true
	outline_material.grow_amount = .005
	
	color_material.next_pass = outline_material
	color_material.roughness = .2
	color_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	color_material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	find_child("Upright_crystal").set_surface_override_material(0, color_material)
	
	#print(color)
	#Hid unneded meshes
	#for mesh in $Armature/Skeleton3D.get_children():
	#	if mesh.name != name:
	#		mesh.visible = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += (delta * bob_speed)
	if not collected:
		var bob_pos
		if int(timer) % 2 == 0:
			bob_pos = (timer - int(timer)) - .5
		else:
			bob_pos = .5 - (timer - int(timer))
		#print(bob_pos)
		global_position.y = init_pos.y + (bob_pos/5)
		
	if collected:
		collected_animation -= delta
		global_position = player.global_position
		rotate_y(-delta * 5)
		global_position.y += 1.3 + abs(collected_animation - 1)
		if collected_animation < 0:
			queue_free()
	
	#if global_position.distance_to(player.global_position) < message_range:
	#	if message:
	#		player.message_ui = message


func _on_body_entered(body):
	if body == player:
		#print("I'm colleded")
		$collected_sound.play()
		player.inventory["crystals"] += value
		#print(player.inventory["crystals"])
		collected = true
