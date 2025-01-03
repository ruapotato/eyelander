extends Node3D

# Music paths
var bg_music = "res://import/CC-BY Kevin MacLeod/Kevin MacLeod - Nu Flute_edit.wav"
var fight_music = "res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav"

@onready var terrain = $Terrain3D
@onready var player = get_player()

# Biome parameters
var biome_noise: FastNoiseLite
var elevation_noise: FastNoiseLite
var moisture_noise: FastNoiseLite

# Biome thresholds
const MOUNTAIN_THRESHOLD = 0.6
const HILLS_THRESHOLD = 0.3
const DESERT_MOISTURE = 0.2
const GRASSLAND_MOISTURE = 0.5
const FOREST_MOISTURE = 0.7

func _ready():
	setup_noise()
	generate_terrain()

func setup_noise():
	# Base elevation noise
	elevation_noise = FastNoiseLite.new()
	elevation_noise.frequency = 0.0005
	elevation_noise.fractal_octaves = 4
	elevation_noise.fractal_lacunarity = 2.0
	elevation_noise.fractal_gain = 0.5
	
	# Moisture noise for biome variation
	moisture_noise = FastNoiseLite.new()
	moisture_noise.frequency = 0.0003
	moisture_noise.fractal_octaves = 2
	
	# Biome distribution noise
	biome_noise = FastNoiseLite.new()
	biome_noise.frequency = 0.0002
	biome_noise.seed = randi()  # Random seed for variation

func generate_terrain():
	var noise_texture = NoiseTexture2D.new()
	noise_texture.width = 1024
	noise_texture.height = 1024
	
	# Create a custom noise generator that combines our noise layers
	var combined_noise = FastNoiseLite.new()
	combined_noise.frequency = 0.0005
	
	# Custom noise generation function
	noise_texture.noise = combined_noise
	noise_texture.as_normal_map = true
	
	# Apply the noise to the terrain
	terrain.material.noise_texture = noise_texture
	terrain.set_collision_enabled(true)

func get_biome_height(x: float, z: float) -> float:
	var base_elevation = elevation_noise.get_noise_2d(x, z)
	var moisture = moisture_noise.get_noise_2d(x, z)
	var biome_value = biome_noise.get_noise_2d(x, z)
	
	# Normalize values to 0-1 range
	base_elevation = (base_elevation + 1.0) * 0.5
	moisture = (moisture + 1.0) * 0.5
	biome_value = (biome_value + 1.0) * 0.5
	
	var final_height = base_elevation
	
	# Apply biome-specific modifications
	if base_elevation > MOUNTAIN_THRESHOLD:
		# Mountains
		final_height *= 2.0  # Increase height for mountains
		final_height += 0.3 * biome_value  # Add noise for peaks
	elif base_elevation > HILLS_THRESHOLD:
		# Hills
		final_height *= 1.5
		final_height += 0.1 * biome_value
	else:
		# Lowlands - vary based on moisture
		if moisture < DESERT_MOISTURE:
			# Desert - slight dunes
			final_height += 0.05 * biome_value
		elif moisture < GRASSLAND_MOISTURE:
			# Grassland - gentle rolls
			final_height += 0.08 * biome_value
		else:
			# Forest or wetland
			final_height += 0.12 * biome_value
	
	return final_height

func _process(_delta):
	var camera = find_player_camera()
	if camera:
		terrain.set_camera(camera)

func get_player():
	var root = get_tree().root
	return root.find_child("player", true, false)

func find_player_camera():
	if player and is_instance_valid(player):
		return player.find_child("Camera3D", true, false)
	return null
