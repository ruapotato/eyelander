extends Node3D

@onready var seg_bit = preload("res://seg_bit.tscn")

@onready var segment_life = 150
@onready var max_segment = 30
#@onready var max_segment = 3
@onready var damage_todo = 0
@onready var start_life = max_segment * segment_life
@onready var life = start_life
@onready var player = get_parent().find_child("player")
var spawn_level = -44
var spawn_count_down = 3
#@onready var spawn_next = preload("res://end_screen.tscn")
var made_trade

func did_i_trade():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.made_trade)

func _ready():
	made_trade = did_i_trade()
	max_segment = int(max_segment * get_parent().hardness) + 1
	start_life = max_segment * segment_life
	life = start_life


#var segments = [[100,100,100,100,100],
#[100,100,100,100,100]]
var segments = []
var dead = false
var init_done = false


func get_segments_bits(index):
	var found = []
	for body in get_children():
		if "segy" in body.name and "segy_" + str(index) in body.name:
			found.append(body)
	return(found)

func setup(delta):
	if not init_done and player.level == 2:
		if player.global_position.y < spawn_level:
			if spawn_count_down > 0:
				if not $spawn.playing:
					$spawn.play()
				spawn_count_down -= delta
				return
			
			print("Spawn Boss 2")
			init_done = true
			segments.append([])
			for i in range(0,max_segment):
				segments[-1].append(100)
			for index in range(0, len(segments)):
				var segment = segments[index]
				var segment_bits = get_segments_bits(index)
				if len(segment) > len(segment_bits):
					var needed = len(segment) - len(segment_bits)
					#print("need to spawn: " + str(needed))
					#print(index)
					for seg_index in range(len(segment_bits), len(segment_bits) + needed):
						var name = "segy_" + str(index) + "_" + str(seg_index)
						var parent_seg = "segy_" + str(index) + "_" + str(seg_index - 1)
						#print("swapn: " + name)
						var new_seg_bit = seg_bit.instantiate()
						new_seg_bit.name = name
						new_seg_bit.index = index
						new_seg_bit.seg_index = seg_index
						new_seg_bit.life = segment_life
						new_seg_bit.set_deferred("global_position", global_position + Vector3(seg_index,global_position.y,seg_index))
						new_seg_bit.ground = global_position.y
						if not made_trade:
							new_seg_bit.visible = false
						if seg_index == 0:
							new_seg_bit.is_head = true
						else:
							new_seg_bit.parent_seg = parent_seg
						add_child(new_seg_bit)

func get_life():
	var life_total = 0 
	for body in get_children():
		if "segy" in body.name:
			life_total += body.life
	return(life_total)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	setup(delta)
	var active_bits = 0
	for body in get_children():
		if "segy" in body.name:
			if body.not_dead:
				active_bits += 1
	
	if init_done:
		life = get_life()
	else:
		life = 0
	if active_bits == 0 and init_done and not dead:
		print("Boss 2 dead")
		#var next_spawn = spawn_next.instantiate()
		#get_parent().add_child(next_spawn)
		
		#open next level
		get_parent().find_child("2_level_plug").queue_free()
		get_parent().find_child("2_level_light").play()
		
		player.level = 3
		player.boss = player.boss_3
		
		dead = true
