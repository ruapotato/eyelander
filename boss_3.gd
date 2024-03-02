extends CharacterBody3D


@onready var mesh = $mesh
@onready var scythe = $scythe

@onready var hurt_sound = $sounds/effects/hurt
@onready var dirt_sounds = $sounds/walking_dirt
@onready var head = $boss_3_head
@onready var target = $target

@onready var spike = preload("res://spike2.tscn")
@onready var win_screen = preload("res://end_screen.tscn")
@onready var game_over_screen = preload("res://game_over.tscn")
#@onready var player = get_parent().find_child("player")
@onready var smoke_effect = find_child("boss_3_particles")
@onready var segment_life = 150
var near = 3

var player
var swipping = false
var swipe_speed = .2
var swipe_counter = 0
var walk_sound_every = 0
var walk_sounds_timer = 0
var walking_on = "dirt"
var dead = false
var action

var mouse_sensitivity = .0035
#var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 15
var SPEED = 5.0

var damage_todo = 0
var start_life = 300
var life = 0
var life_gen = 4
var boss_life = 0
#var swipe_start_angle = 180
#var swipe_end_angle = 30
var swipe_stage = 1

var scythe_hold_angle = 123
var scythe_center_angle = 180
var scythe_far_left_angle = 250
var swipe_angles = {1: [scythe_hold_angle, scythe_far_left_angle],
					2: [scythe_far_left_angle,scythe_hold_angle]}
#					3: [scythe_hold_angle, scythe_far_left_angle]}

var shilding = false
var shild_hold_angle = 90
var shilding_angle = 0
var knockback = Vector3(0,0,0)
var dazzed = 0
var new_speed = Vector3(0,0,0)
var init_done = false

var made_trade

var stage = 1
var stage_counter = 0
var change_every = 8 # seconds to stay in a stage
var shoot_every = 2
var shoot_timer = shoot_every



func did_i_trade():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.made_trade)

func _ready():
	scythe.visible = true
	made_trade = did_i_trade()
	player = get_player()
	#start_life = start_life * get_parent().hardness
	#life = start_life
	


func get_target():
	return(player.global_position + Vector3(0,.2,0))


func process_action(delta):
	
	var dist_to_player = global_position.distance_to(get_target())
	
	
	if head.mounted:
		if stage == 1:
			if dist_to_player < near:
				#scythe.visible = true
				action = "swipping"
			else:
				action = "walking"
				#scythe.visible = false
		if stage != 1:
			if dist_to_player < near * 3:
				action = "tp"
			else:
				action = "shoot_bits"
	if not head.mounted:
		action = "rage"
		#print("rage!!!")
	
	
	if action == "tp":
		#var new_pos = Vector3(randf_range(-30,30),global_position.y,randf_range(-30,30))
		global_position.x += randf_range(-30,30)
		global_position.z += randf_range(-30,30)
		#global_position = new_pos + player.global_position
	
	
	if action == "shoot_bits":
		if shoot_timer > 0:
			shoot_timer -= delta
		else:
			# Shoot bit
			#print("add spike")
			#head.shoot = true
			var new_spike = spike.instantiate()
			new_spike.set_deferred("global_position", global_position + Vector3(0,1,0))
			#new_spike.ground = global_position.y
			new_spike.player = player
			get_parent().add_child(new_spike)
			shoot_timer = shoot_every
	
	if action == "swipping" or action == "rage":
		if swipe_counter <= 0:
			swipping = true
			swipe_counter = swipe_speed
			swipe_stage += 1
			if swipe_stage > len(swipe_angles):
				swipe_stage = 1

				if not scythe.find_child("swing").playing:
					scythe.find_child("swing").play()

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

func walk_sound():
	if walking_on == "dirt":
		var sound_to_use = dirt_sounds.get_children().pick_random()
		#var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()


func _physics_process(delta):
	if not init_done:
		return
	if dead:
		return

	walk_sound_every = 1/(velocity.length()/3)
	new_speed = velocity
	if knockback != Vector3(0,0,0):
		dazzed = knockback.length() / 100
		new_speed = knockback
		new_speed.y = abs(new_speed.y)
		#print(new_speed)
		#new_speed = knockback
		knockback = Vector3(0,0,0)
	if dazzed > 0:
		dazzed -= delta
		#print(dazzed)
	else:
		dazzed = 0
	# Add the gravity.
	if global_position.y < 0:
		new_speed.y += gravity * delta
	elif not is_on_floor():
		new_speed.y -= gravity * delta
		#if global_position.distance_to(Vector3(0,global_position.y,0)) < 30:
		#	new_speed.y -= gravity * delta * .2

	# Handle Jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
	#	new_speed.y += JUMP_VELOCITY
		#swipe_stage = 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if dazzed == 0:
		if not action == "rage":
			global_rotation.y = lerp_angle(global_rotation.y, target.global_rotation.y, .1)

		if action == "walking":
			# move away from a jumping player
			var input_dir
			if player.is_on_floor():
				input_dir = Vector3(0,1,0)
			else:
				input_dir = Vector3(0,-1,0)
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			new_speed.x = lerp(new_speed.x, direction.x * SPEED, .2)
			new_speed.z = lerp(new_speed.z, direction.z * SPEED, .2)
			#target.look_at(get_target(), Vector3(0,1,0))
			
			#look_at(get_target())
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_sounds_timer = 0
				#print("wlak sound")
		if action != "walking":
			new_speed.x = lerp(new_speed.x, 0.0, .2)
			new_speed.z = lerp(new_speed.z, 0.0, .2)
	
	
	
	var swipe_done = swipe_stage > len(swipe_angles)
	if swipe_done:
		#scythe.visible = false
		if  scythe.find_child("swing").playing:
			scythe.find_child("swing").stop()
	
	if (swipping and not swipe_done) and not shilding:
		if is_on_floor():
			scythe.rotation.x = lerp(scythe.rotation.x, rotation.x * -1, .3)
			#print(scythe.rotation.x)
			var swipe_end_angle
			var swipe_start_angle
			if action != "rage":
				swipe_end_angle = swipe_angles[swipe_stage][0]
				swipe_start_angle =   swipe_angles[swipe_stage][1]
			else:
				swipe_end_angle = 0
				swipe_start_angle = 360
			
			#print(swipe_counter)
			swipe_counter -= delta
			if swipe_counter <= 0:
				swipe_counter = 0
				swipping = false
			else:
				var angle_amount = swipe_counter/swipe_speed
				var total_angles = swipe_end_angle - swipe_start_angle
				var angle = (total_angles * angle_amount) + swipe_start_angle
				#print(angle)
				#TODO direct at player
				scythe.rotation_degrees.y = angle + 180#+ rotation_degrees.y
				#scythe.rotation.z = 0
				#print(scythe.rotation_degrees.y)
		if swipping and not shilding and not is_on_floor():
			#if new_speed.y < 0:
			#scythe.look_at(camera.global_position, Vector3(1,0,0))
			if not scythe.find_child("swing2").playing:
				scythe.find_child("swing2").play()
			scythe.rotation_degrees.y = lerp(scythe.rotation_degrees.y, scythe_center_angle + rotation_degrees.y, .2)
			#scythe.rotate_object_local(Vector3(0,0,1), .5)
			
			scythe.rotation.z = lerp(scythe.rotation.z , 1.5, .3)
			
			#if  is_equal_approx(scythe.rotation.z, 1.5):
			scythe.rotation.x = lerp(scythe.rotation.x ,rotation.x * -1, .2)
	if (not swipping or swipe_done) and not shilding:
		#scythe.rotation.y = lerp_angle(scythe.rotation.y, atan2(-direction.x, -direction.z), .2)
		#if not Input.is_action_pressed("swipe"):
		scythe.rotation_degrees.y = scythe_hold_angle + rotation_degrees.y 
		scythe.rotation.z = 0
		scythe.rotation.x = 0
		
		#print(scythe.rotation.y)
	velocity = new_speed
	move_and_slide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if not init_done:
		if global_position.distance_to(player.global_position) < 5:
			init_done = true
			life = start_life
			smoke_effect.emitting = true
			print("Boss 3 ready")
		return
	
	stage_counter += delta
	stage = (int(stage_counter/change_every) % 2) + 1
	#print(stage)
	
	target.look_at(player.global_position, Vector3(0,1,0))
	target.rotate_object_local(Vector3(0,1,0),3)
	#target.look_at(player.global_position, Vector3(0,1,0))
	#target.look_at(get_target(), Vector3(0,-1,0))
	#look_at(player.global_position)
	process_action(delta)
	
	if life < start_life:
		life += delta * life_gen
	elif life > start_life:
		life = start_life

	if damage_todo != 0:
		if damage_todo > 30:
			hurt_sound.play()
			# Hard mode, pop head
			if life/start_life < .7:
				head.pop_off_counter = head.pop_off_for
				head.mounted = false
			
		life -= damage_todo
		damage_todo = 0
		if life <= 0 and not dead:
			print("boss 3 dead")
			player.has_won = true
			#var RIP = game_over_screen.instantiate()
			#get_parent().add_child(RIP)
			var next_spawn = win_screen.instantiate()
			get_parent().add_child(next_spawn)
			dead = true
			#get_tree().reload_current_scene()
		#print(life)
