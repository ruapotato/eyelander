extends Node3D

# Music paths
var bg_music = "res://import/CC-BY Kevin MacLeod/Kevin MacLeod - Nu Flute_edit.wav"
var fight_music = "res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav"
@onready var terrain = $Terrain3D
@onready var player = get_player()


func _ready():
	# Create a terrain
	#terrain = Terrain3D.new()
	#terrain.assets = Terrain3DAssets.new()
	terrain.name = "Terrain3D"
	terrain.set_collision_enabled(false)
	add_child(terrain, true)
	terrain.material.world_background = Terrain3DMaterial.NONE
	
	# Generate 32-bit noise and import it with scale
	var noise := FastNoiseLite.new()
	noise.frequency = 0.0005
	var img: Image = Image.create(2048, 2048, false, Image.FORMAT_RF)
	for x in 2048:
		for y in 2048:
			img.set_pixel(x, y, Color(noise.get_noise_2d(x, y)*0.5, 0., 0., 1.))
	terrain.data.import_images([img, null, null], Vector3(-1024, 0, -1024), 0.0, 300.0)

	# Enable collision. Enable the first if you wish to see it with Debug/Visible Collision Shapes
	#terrain.set_show_debug_collision(true)
	terrain.set_collision_enabled(true)
	
	# Enable runtime navigation baking using the terrain
	$RuntimeNavigationBaker.terrain = terrain
	$RuntimeNavigationBaker.enabled = true
	
	terrain.material.shader_override_enabled = true
	terrain.material.auto_shader = true
	terrain.material.shader_override = preload("res://native/eyeball_world2.gdshader")
	
	# Initial camera setup
	var camera = find_player_camera()
	if camera:
		terrain.set_camera(camera)
		
	

func _process(_delta):
	if !terrain:
		return
		
	# Update camera every frame in case it changes
	var camera = find_player_camera()
	if camera:
		terrain.set_camera(camera)

func get_player():
	var root = get_tree().root
	return root.find_child("player", true, false)

func find_player_camera():
	# Look for camera in player's children
	if player:
		return player.find_child("Camera3D", true, false)
	return null
