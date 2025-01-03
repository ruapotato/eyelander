extends Node3D

const CHUNK_SIZE = 256  # Size of each terrain chunk in units
const LOAD_DISTANCE = 2  # How many chunks to load in each direction from player
const UNLOAD_DISTANCE = 3  # How many chunks away before unloading

# Music paths
var bg_music = "res://import/CC-BY Kevin MacLeod/Kevin MacLeod - Nu Flute_edit.wav"
var fight_music = "res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav"

var active_chunks = {}  # Dictionary to store loaded chunks
var noise: FastNoiseLite
@onready var terrain = $Terrain3D
@onready var player = get_player()

class TerrainChunk:
	var position: Vector2  # Chunk grid position
	var terrain_instance: Terrain3D
	var is_loaded: bool = false
	var is_generating: bool = false
	
	func _init(pos: Vector2, parent_node: Node, source_terrain: Terrain3D):
		position = pos
		terrain_instance = Terrain3D.new()
		terrain_instance.name = "Chunk_%d_%d" % [pos.x, pos.y]
		
		# Setup terrain properties
		terrain_instance.debug_level = source_terrain.debug_level
		terrain_instance.collision_mask = source_terrain.collision_mask
		terrain_instance.assets = source_terrain.assets
		
		# Create and setup material
		var new_material = Terrain3DMaterial.new()
		new_material.world_background = source_terrain.material.world_background
		new_material.shader_override_enabled = true
		
		# Copy shader parameters
		for param in source_terrain.material._shader_parameters:
			new_material._shader_parameters[param] = source_terrain.material._shader_parameters[param]
			
		terrain_instance.material = new_material
		terrain_instance.material.shader_override = source_terrain.material.shader_override
		
		# Ensure collision is disabled initially
		terrain_instance.set_collision_enabled(false)
		parent_node.add_child(terrain_instance)
	
	func generate_terrain(noise: FastNoiseLite):
		if is_generating or is_loaded:
			return
			
		is_generating = true
		
		# Create heightmap image
		var img: Image = Image.create(CHUNK_SIZE + 1, CHUNK_SIZE + 1, false, Image.FORMAT_RF)
		var world_pos = position * CHUNK_SIZE
		
		for x in CHUNK_SIZE + 1:
			for y in CHUNK_SIZE + 1:
				var world_x = world_pos.x + x
				var world_y = world_pos.y + y
				img.set_pixel(x, y, Color(noise.get_noise_2d(world_x, world_y) * 0.5, 0., 0., 1.))
		
		# Import terrain data with safety checks
		terrain_instance.data.import_images([img, null, null], Vector3(world_pos.x, 0, world_pos.y), 0.0, 300.0)
		
		# Wait for two frames to ensure data is properly imported
		await terrain_instance.get_tree().process_frame
		await terrain_instance.get_tree().process_frame
		
		# Enable collision only if still valid
		if is_instance_valid(terrain_instance):
			terrain_instance.set_collision_enabled(true)
			is_loaded = true
		
		is_generating = false
		
	func unload():
		if is_loaded:
			# Disable collision first
			if is_instance_valid(terrain_instance):
				terrain_instance.set_collision_enabled(false)
				# Wait a frame before freeing
				await terrain_instance.get_tree().process_frame
				terrain_instance.queue_free()
			is_loaded = false
			is_generating = false

func _ready():
	noise = FastNoiseLite.new()
	noise.frequency = 0.0005
	
	# Hide the original terrain after copying its settings
	terrain.visible = false
	terrain.set_collision_enabled(false)
	
	call_deferred("update_chunks")

func _process(_delta):
	call_deferred("update_chunks")
	update_camera()

func update_camera():
	var camera = find_player_camera()
	if camera:
		for chunk in active_chunks.values():
			if chunk.is_loaded and is_instance_valid(chunk.terrain_instance):
				chunk.terrain_instance.set_camera(camera)

func update_chunks():
	if !player or !is_instance_valid(player):
		return
		
	var player_pos = player.global_transform.origin
	var chunk_pos = Vector2(
		floor(player_pos.x / CHUNK_SIZE),
		floor(player_pos.z / CHUNK_SIZE)
	)
	
	# Load new chunks
	for x in range(-LOAD_DISTANCE, LOAD_DISTANCE + 1):
		for y in range(-LOAD_DISTANCE, LOAD_DISTANCE + 1):
			var check_pos = Vector2(chunk_pos.x + x, chunk_pos.y + y)
			if !active_chunks.has(check_pos):
				var new_chunk = TerrainChunk.new(check_pos, self, terrain)
				active_chunks[check_pos] = new_chunk
				new_chunk.call_deferred("generate_terrain", noise)
	
	# Unload distant chunks
	var chunks_to_unload = []
	for pos in active_chunks:
		if !active_chunks[pos].is_generating:  # Don't unload generating chunks
			var distance = (pos - chunk_pos).length()
			if distance > UNLOAD_DISTANCE:
				chunks_to_unload.append(pos)
	
	for pos in chunks_to_unload:
		if active_chunks.has(pos):  # Check if still exists
			await active_chunks[pos].unload()
			active_chunks.erase(pos)

func get_player():
	var root = get_tree().root
	return root.find_child("player", true, false)

func find_player_camera():
	if player and is_instance_valid(player):
		return player.find_child("Camera3D", true, false)
	return null
