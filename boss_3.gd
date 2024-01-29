extends CharacterBody3D


@onready var mesh = $mesh
@onready var scythe = $scythe

@onready var hurt_sound = $sounds/effects/hurt
@onready var dirt_sounds = $sounds/walking_dirt

@onready var target = $target

@onready var win_screen = preload("res://end_screen.tscn")
@onready var game_over_screen = preload("res://game_over.tscn")
@onready var player = get_parent().find_child("player")
@onready var smoke_effect = find_child("boss_3_particles")
var near = 3


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
var life = start_life
var life_gen = 2
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

func did_i_trade():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.made_trade)

func _ready():
	scythe.visible = false
	made_trade = did_i_trade()
	start_life = start_life * get_parent().hardness
	life = start_life
	
	if not made_trade:
		find_child("mesh").visible = false
		$boss_3_effect.visible = false
		$scythe.visible = false


func get_target():
	return(player.global_position + Vector3(0,.2,0))


func process_action():
	
	var dist_to_player = global_position.distance_to(get_target())
	
	if dist_to_player < near:
		scythe.visible = true
		action = "swipping"
	else:
		action = "walking"
	
	
	if action == "swipping":
		if swipe_counter <= 0:
			swipping = true
			swipe_counter = swipe_speed
			swipe_stage += 1
			if swipe_stage > len(swipe_angles):
				swipe_stage = 1

				if not scythe.find_child("swing").playing:
					scythe.find_child("swing").play()

	

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
	if not is_on_floor():
		if global_position.distance_to(Vector3(0,global_position.y,0)) < 30:
			new_speed.y -= gravity * delta * .2

	# Handle Jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
	#	new_speed.y += JUMP_VELOCITY
		#swipe_stage = 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if dazzed == 0:
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
	
	
	
	if dazzed == 0:
		if is_on_floor():
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_sounds_timer = 0
			#print("wlak sound")
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPEED
		if shilding:
			speed = SPEED / 2
		elif Input.is_action_pressed("sprint"):
			speed = SPEED * 2
		if direction:
			new_speed.x = lerp(new_speed.x, direction.x * speed, .2)
			new_speed.z = lerp(new_speed.z, direction.z * speed, .2)
		else:
			new_speed.x = lerp(new_speed.x, 0.0, .2)
			new_speed.z = lerp(new_speed.z, 0.0, .2)
			#new_speed.x += move_toward(velocity.x, 0, SPEED)
			#new_speed.z += move_toward(velocity.z, 0, SPEED)
	
	var swipe_done = swipe_stage > len(swipe_angles)
	if swipe_done:
		scythe.visible = false
		if  scythe.find_child("swing").playing:
			scythe.find_child("swing").stop()
	
	if (swipping and not swipe_done) and not shilding:
		if is_on_floor():
			scythe.rotation.x = lerp(scythe.rotation.x, rotation.x * -1, .3)
			#print(scythe.rotation.x)
			var swipe_end_angle = swipe_angles[swipe_stage][0]
			var swipe_start_angle =   swipe_angles[swipe_stage][1]
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
		if player.level == 3:
			if player.global_position.y < -70:
				init_done = true
				smoke_effect.emitting = true
				print("Boss 3 ready")
		return
	target.look_at(player.global_position, Vector3(0,1,0))
	target.rotate_object_local(Vector3(0,1,0),3)
	#target.look_at(player.global_position, Vector3(0,1,0))
	#target.look_at(get_target(), Vector3(0,-1,0))
	#look_at(player.global_position)
	process_action()
	
	if life < 100:
		life += delta * life_gen
	elif life > 100:
		life = 100
	
	if damage_todo != 0:
		if damage_todo > 15:
			hurt_sound.play()
		life -= damage_todo
		damage_todo = 0
		if life <= 0 and not dead:
			print("boss 3 dead")
			#var RIP = game_over_screen.instantiate()
			#get_parent().add_child(RIP)
			var next_spawn = win_screen.instantiate()
			get_parent().add_child(next_spawn)
			dead = true
			#get_tree().reload_current_scene()
		#print(life)
