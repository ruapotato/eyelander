extends Node3D
@onready var music = $music
@onready var env = $WorldEnvironment
@onready var player = $player
@onready var Tree1Scene = preload("res://big_shoom.tscn")
@onready var boboScene = preload("res://bobo.tscn")
# Big thanks to https://github.com/fbcosentino/godot-audiostreampreview/blob/main/addons/audio_preview/voice_preview_generator.gd
# From https://godotengine.org/asset-library/asset/2257

var data
#var stream
#var this_stream
#var data_size
#var is_16bit
#var is_stereo

var final_sample_i = 0
var image_max_width = 2000
const MAX_FREQUENCY: float = 3000.0 # Maximum frequency captured
const SAMPLING_RATE = 2.0*MAX_FREQUENCY

var sound_light_data

var norm_sound_light_data = []
var hard_sound_light_data = []
var repeat = true
var hardness = 1
var game_index = null
var made_trade
var lava_level = 0
var inverce_light_power = 300.0
var normal_music = preload("res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav")
var hard_end_music = preload("res://import/CC BY BoxCat Games/BoxCat Games - Battle (End).wav")
var home_island = preload("res://home_island.tscn")
var last_boss = null
var water = null
var last_known_pos = Vector3(-1,-1,-1)
#const IMAGE_HEIGHT_FACTOR: float = float(IMAGE_HEIGHT) / 256.0 # Converts sample raw height to pixel
#const IMAGE_CENTER_Y = int(round(IMAGE_HEIGHT / 2.0))

var init_load = null
var loaded

var _tree_count = 100
var trees = []
var chunk_size = 3
var render_range = 100
var chunk_in_mem = []
var rendred_trees = []
var tree_index = 0
var bg_music = null
var fight_music = null


var img_x = 0


func load_place(what_and_where):
	print(what_and_where)
	if loaded:
		loaded.queue_free()
	var what = what_and_where[0]
	loaded = what.instantiate()
	fight_music = load(loaded.fight_music)
	bg_music = load(loaded.bg_music)
	if loaded.find_child("water"):
		water = loaded.find_child("water")
	else:
		water = null
	add_child(loaded)
	var where = loaded.find_child(what_and_where[1]).position
	var rot = loaded.find_child(what_and_where[1]).rotation
	print(where)
	player.global_position = where
	player.piv.rotation = rot

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	load_place(init_load)
	for i in range(0,int(_tree_count)):
		trees.append(Tree1Scene.instantiate())
		#trees[-1].gravity_scale = 0
		trees[-1].position = Vector3((randi()%60)-30,-100,(randi()%60)-30)
		#trees[-1].contact_monitor = true
		#trees[-1].max_contacts_reported = 99999
		trees[-1].name = "tree_" + str(len(trees))
		add_child.call_deferred(trees[-1])


"""
func get_most_dist(some_list_of_objects, from=player): 
	var most_dist = some_list_of_objects[0]
	for object in some_list_of_objects:
		if object.global_position.distance_to(player.global_position) > most_dist.global_position.distance_to(player.global_position):
			most_dist = object
	return(most_dist)

	var chunk_index_to_reuse = 0
	for i in range(1, len(some_list_of_objects)):
		var terrain_dist = some_list_of_objects[i].position.distance_to(from.position)
		var known_best_dist = some_list_of_objects[chunk_index_to_reuse].position.distance_to(from.position)
		if terrain_dist > known_best_dist:
			chunk_index_to_reuse = i
	return(some_list_of_objects[chunk_index_to_reuse])
	"""

func get_player_grid_pos():
	var x_pos = int(player.global_position.x/chunk_size)
	var y_pos = int(player.global_position.y/chunk_size)
	var z_pos = int(player.global_position.z/chunk_size)
	return(Vector3(x_pos,y_pos,z_pos))

func spawn(what, where_and_size):
	if what == Tree1Scene:
		#var what_to_use = get_most_dist(trees)
		var what_to_use = trees[tree_index]
		if what_to_use in rendred_trees:
			rendred_trees.erase(what_to_use)
		tree_index += 1
		if tree_index >= len(trees):
			tree_index = 0
		what_to_use.global_position = where_and_size[0]
		what_to_use.scale = where_and_size[1]


func get_needed_trees():
	var needed = []
	if loaded.name == "home_island":
		for mush in loaded.find_child("big_mushes").get_children():
			var mush_pos = mush.global_position
			if mush_pos.distance_to(player.global_position) < render_range:
				needed.append([mush_pos, mush.scale])
	return(needed)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if music.stream != bg_music:
		music.stream = bg_music
		music.play()
		
	#print(Engine.get_frames_per_second())
	if not player or not player.level:
		queue_free()
		return
	
	# load new level if needed
	if player.needs_to_load != null:
		print(player.needs_to_load)
		load_place(player.needs_to_load)
		player.needs_to_load = null
	
	# Update water
	if water:
		if abs(water.global_position.x - player.global_position.x) > 20:
			water.global_position.x = player.global_position.x
		if abs(water.global_position.z - player.global_position.z) > 20:
			water.global_position.z = player.global_position.z
	
	# Update trees
	#print(last_known_pos)
	if get_player_grid_pos() != last_known_pos:
		last_known_pos = get_player_grid_pos()
		for needed_tree in get_needed_trees():
			if needed_tree not in rendred_trees:
				rendred_trees.append(needed_tree[0])
				spawn(Tree1Scene, needed_tree)
	"""
	#update lava level
	if player.level != lava_level:
		lava_level = player.level
		if lava_level == 1:
			find_child("lava").global_position.y = 130
		if lava_level == 2:
			find_child("lava").global_position.y = 70
		if lava_level == 3:
			find_child("lava").global_position.y = 0
	
	var boss_life = (float(player.boss.life)/float(player.boss.start_life))*100
	#Swich to normal music
	if last_boss != player.boss:
		last_boss = player.boss
		if music.stream == hard_end_music:
			print("Set normal music")
			music.stream = normal_music
			sound_light_data = norm_sound_light_data
	
	#Swich to hard
	if boss_life <= 50 and player.boss.life > 0:
		if music.stream == normal_music:
			print("Set hard music")
			music.stream = hard_end_music
			sound_light_data = hard_sound_light_data
		inverce_light_power = boss_life * 30
		$music.volume_db = clamp((50/player.boss.life) -1,0,4)
	else:
		inverce_light_power = 900.0
		$music.volume_db = 0
	#Update lighting
	#if not made_trade:
	#	if $WorldEnvironment:
	#		$WorldEnvironment.environment.fog_enabled = false
	#	if $sun:
	#		$sun.light_energy = .3
	if false:
		if not music:
			return
		#print(get_playback_position())
		if music.playing:
			var pos = music.get_playback_position()
			var length = music.stream.get_length()
			#print(pos)
			#print(length)
			#print(len(reduced_data))
			var index = (pos/length) * len(sound_light_data)
			var min_max = sound_light_data[int(index)]
			var DB = min_max[1] - min_max[0]
			#print(DB)
			if inverce_light_power == 0:
				inverce_light_power = .0001
			var light_power = DB / inverce_light_power
			$WorldEnvironment.environment.fog_light_energy  = lerp($WorldEnvironment.environment.fog_light_energy,light_power,.9)

		elif repeat:
			music.play()
		#	$WorldEnvironment.environment.fog_light_energy  = 0
"""
