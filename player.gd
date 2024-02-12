extends CharacterBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
@onready var mesh = $mesh
@onready var sword = $sword
@onready var shild = $shild
@onready var camera = $piv/SpringArm3D/Camera3D
@onready var gui = $GUI
@onready var hurt_sund = $hurt
@onready var dirt_sounds = $sounds/walking_dirt
@onready var collisionshape = $CollisionShape3D
@onready var boss = get_parent().find_child("boss_1")
@onready var boss_2 = get_parent().find_child("boss_2")
@onready var boss_3 = get_parent().find_child("boss_3")
@onready var game_over_screen = preload("res://game_over.tscn")
@onready var root = get_parent().get_parent()
@onready var animation_tree = get_node("mesh/AnimationTree")
@onready var right_hand_bone = get_node("mesh/Armature/Skeleton3D/right_hand")
@onready var left_hand_bone = get_node("mesh/Armature/Skeleton3D/left_hand")
@onready var swipe_1_effect = $CollisionShape3D/swipes/swipe_1
@onready var swipe_2_effect = $CollisionShape3D/swipes/swipe_2
@onready var swipe_3_effect = $CollisionShape3D/swipes/swipe_3

var total_swipe_stages = 3
var swipe_stage = 1
var walk_sound_every = 0
var walk_sounds_timer = 0
var walking_on = "dirt"
var dead = false
var wind = Vector3(0,0,0)
var max_zoom = 4.75
var min_zoom = -.25

var mouse_sensitivity = .0035
#var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 15
var SPEED = 5.0

var level = 1
var swipping = false
var swipe_speed = .3
var swipe_counter = 0
var damage_todo = 0
var start_life = 100
var life = start_life
var life_gen = .5
var boss_life = 0
#var swipe_start_angle = 180
#var swipe_end_angle = 30


var sword_hold_angle = 123
var sword_center_angle = 180
var sword_far_left_angle = 250
var swipe_angles = {1: [sword_hold_angle, sword_far_left_angle],
					2: [sword_far_left_angle,sword_hold_angle]}
#					3: [sword_hold_angle, sword_far_left_angle]}

var shilding = false
var shild_hold_angle = 90
var shilding_angle = 0
var knockback = Vector3(0,0,0)
var dazzed = 0
var new_speed = Vector3(0,0,0)
var og_camera_angle
var shake = 0
var walk_shake = 0
var has_won = false
var effects_effector
var use_controler = false
var acton_name
# Called when the node enters the scene tree for the first time.
func _ready():
	og_camera_angle = camera.rotation_degrees
	start_life = start_life / get_parent().hardness
	life_gen = life_gen / get_parent().hardness
	life = start_life
	
	acton_name = "parameters/swipe_" + str(swipe_stage)
	#Setup mouse settins
	if root.mouse_sensitivity_effector > 0:
		for i in range(0, int(root.mouse_sensitivity_effector)):
			mouse_sensitivity *= 1.2
	elif  root.mouse_sensitivity_effector < 0:
		for i in range(0, int(abs(root.mouse_sensitivity_effector))):
			mouse_sensitivity *= .8
	
	#Setup effects
	effects_effector = root.effects_effector
	#print(effects_effector)


func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	
	if Input.is_action_just_pressed("zoom_out"):
		#print(find_child("SpringArm3D").spring_length)
		if max_zoom >= find_child("SpringArm3D").spring_length + .25:
			find_child("SpringArm3D").spring_length += .25
	
	if Input.is_action_just_pressed("zoom_in"):
		#print(find_child("SpringArm3D").spring_length)
		if min_zoom <= find_child("SpringArm3D").spring_length - .25:
			find_child("SpringArm3D").spring_length -= .25
	
	#Controler controls
	#if event is InputEventJoypadMotion:
		#if event.axis == 2:
		#	piv.rotate_y(event.axis_value * -mouse_sensitivity * 10)

			#print(event.device)
			#spring_arm.rotate_x(event.axis_value * -mouse_sensitivity * 100)
			#spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)

		#piv.rotate_y(event.relative.x * -mouse_sensitivity)
	
	#Mouse controls
	if event is InputEventMouseMotion and not dead and not has_won:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		
		

	if Input.is_action_just_released("swipe"):
		#swipe_stage = 1
		if sword.find_child("swing").playing:
			sword.find_child("swing").stop()
	
	if Input.is_action_just_pressed("shild"):
		shilding = true
		if sword.find_child("swing").playing:
			sword.find_child("swing").stop()
			swipping = false
	if Input.is_action_just_released("shild"):
		shilding = false
		if Input.is_action_pressed("swipe"):
			sword.find_child("swing").play()
	
	#Update sowrd
	#var swipping = false
	#var swipe_speed = 1
	#var swipe_start_angle = 30
	#var swipe_end_angle = 120

func walk_sound():
	if walking_on == "dirt":
		var sound_to_use = dirt_sounds.get_children().pick_random()
		#var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()


func _physics_process(delta):
	if dead:
		return
	walk_sound_every = 1/(velocity.length()/3)
	new_speed = velocity
	if wind != Vector3(0,0,0):
		new_speed += wind
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
		new_speed.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		new_speed.y += JUMP_VELOCITY
		#swipe_stage = 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if dazzed == 0:
		if is_on_floor():
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_shake = abs((velocity.length()/10) - 1.5)/2
				#print(walk_shake)
				walk_sounds_timer = 0
			#print("wlak sound")
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (piv.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPEED
		if shilding:
			speed = SPEED / 2
		elif Input.is_action_pressed("sprint"):
			speed = SPEED * 2
		if direction and not Input.is_action_pressed("swipe"):
			new_speed.x = lerp(new_speed.x, direction.x * speed, delta * 8)
			new_speed.z = lerp(new_speed.z, direction.z * speed, delta * 8)
		else:
			new_speed.x = lerp(new_speed.x, 0.0, delta * 5)
			new_speed.z = lerp(new_speed.z, 0.0, delta * 5)
			#new_speed.x += move_toward(velocity.x, 0, SPEED)
			#new_speed.z += move_toward(velocity.z, 0, SPEED)

	"""
	if shilding:
		# Set shilding pos
		shild.rotation_degrees.y = lerp(shild.rotation_degrees.y, shilding_angle + piv.rotation_degrees.y, .2)
		# Set camera 
		#shild.rotation_degrees.x = spring_arm.rotation_degrees.x
		# Set sword pos
		sword.rotation_degrees.y = piv.rotation_degrees.y - 100
	if not shilding:
		shild.rotation_degrees.y = shild_hold_angle + piv.rotation_degrees.y
	"""
	"""
	var swipe_done = swipe_stage > len(swipe_angles)
	if swipe_done and sword.find_child("swing").playing:
		sword.find_child("swing").stop()
	if (swipping and not swipe_done) and not shilding:
		if is_on_floor():
			sword.rotation.x = lerp(sword.rotation.x, spring_arm.rotation.x * -1, .3)
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
				sword.rotation_degrees.y = angle + piv.rotation_degrees.y
				sword.rotation.z = 0
				#print(sword.rotation_degrees.y)
		if swipping and not shilding and not is_on_floor():
			#if new_speed.y < 0:
			#sword.look_at(camera.global_position, Vector3(1,0,0))
			if not sword.find_child("swing2").playing:
				sword.find_child("swing2").play()
			sword.rotation_degrees.y = lerp(sword.rotation_degrees.y, sword_center_angle + piv.rotation_degrees.y, .2)
			#sword.rotate_object_local(Vector3(0,0,1), .5)
			
			sword.rotation.z = lerp(sword.rotation.z , 1.5, .3)
			
			#if  is_equal_approx(sword.rotation.z, 1.5):
			sword.rotation.x = lerp(sword.rotation.x ,spring_arm.rotation.x * -1, .2)
	if (not swipping or swipe_done) and not shilding:
		#sword.rotation.y = lerp_angle(sword.rotation.y, atan2(-direction.x, -direction.z), .2)
		#if not Input.is_action_pressed("swipe"):
		sword.rotation_degrees.y = sword_hold_angle + piv.rotation_degrees.y 
		sword.rotation.z = 0
		sword.rotation.x = 0
		
		#print(sword.rotation.y)
	"""
	velocity = new_speed
	move_and_slide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if boss_life != boss.life:
		boss_life = boss.life
		if gui.find_child("BOSS_LIFE"):
			var new_life = (float(boss.life)/float(boss.start_life)) * 100
			gui.find_child("BOSS_LIFE").value = new_life
			if new_life < 50 and new_life != 0:
				gui.find_child("dragon_pissed").visible = true
			else:
				gui.find_child("dragon_pissed").visible = false
				
		if level == 1:
			gui.find_child("BOSS_LABLE").text = "Spider Boss"
		if level == 2:
			gui.find_child("BOSS_LABLE").text = "Worm Boss"
		if level == 3:
			gui.find_child("BOSS_LABLE").text = "Reaper Boss"
	
	if walk_shake > 0:
		var walk_angle = Vector3(20,0,0)
		camera.rotation_degrees = lerp(camera.rotation_degrees, walk_angle, delta * (velocity.length()/5))
		walk_shake -= delta
	elif walk_shake < 0:
		walk_shake = 0
	else:
		camera.rotation_degrees = lerp(camera.rotation_degrees, og_camera_angle, .01)
	
	if swipping:
		swipe_counter -= delta
		if swipe_counter <= 0:
			swipe_counter = 0
			swipping = false
	
	if wind.length() > 0:
		var randome_angle = Vector3(randf_range(-180,180),randf_range(-180,180),randf_range(-180,180))
		camera.rotation_degrees = lerp(camera.rotation_degrees, randome_angle, .003 * wind.length())
		wind = lerp(wind, Vector3(0,0,0),.3)
	
	if shake > 0:
		var randome_angle = Vector3(randf_range(-180,180),randf_range(-180,180),randf_range(-180,180))
		camera.rotation_degrees = lerp(camera.rotation_degrees, randome_angle, .03 * shake)
		shake -= delta
	elif shake < 0:
		shake = 0
	else:
		camera.rotation_degrees = lerp(camera.rotation_degrees, og_camera_angle, .03)
	
	if life < start_life:
		life += delta * life_gen
		gui.find_child("LIFE").value = (life/start_life) * 100
	elif life > start_life:
		life = start_life
	
	if damage_todo != 0:
		if not has_won:
			if damage_todo > 15:
				hurt_sund.play()
				shake = 1
			life -= damage_todo
		gui.find_child("LIFE").value = life
		damage_todo = 0
		if life <= 0 and not dead:
			print("You are dead")
			var RIP = game_over_screen.instantiate()
			get_parent().add_child(RIP)
			dead = true
	
	#Rotate player
	mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-velocity.x, -velocity.z), delta * 5)
	collisionshape.rotation.y = mesh.rotation.y
	
	#set animations
	animation_tree.set("parameters/stand_run/blend_position", velocity.length()/SPEED)
	if velocity.length()/SPEED > 1:
		animation_tree.set("parameters/run_timescale/scale", velocity.length()/SPEED)
		print(velocity.length()/SPEED)
	else:
		animation_tree.set("parameters/run_timescale/scale", 1)
	
	
	#Controls
	var is_active = animation_tree.get(acton_name + "/active")
	if Input.is_action_pressed("swipe"):
		if not is_active:
			#animation_tree.set(acton_name + "/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
			acton_name = "parameters/swipe_" + str(swipe_stage)
			animation_tree.set(acton_name + "/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			#animation_tree.set("parameters/swipe_3/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			print("Play " + str(swipe_stage))
			swipe_counter = swipe_speed
			#if not sword.find_child("swing").playing:
			sword.find_child("swing").play()
			if swipe_stage == 1:
				swipe_1_effect.playing = true
				#print("play1")
			if swipe_stage == 2:
				swipe_2_effect.playing = true
				#print("play2")
			if swipe_stage == 3:
				swipe_3_effect.playing = true
				#print("play3")
			swipe_counter = swipe_speed
			swipping = true
			swipe_stage += 1
			if swipe_stage > total_swipe_stages:
				#print("reset")
				swipe_stage = 1
	else:
		if not is_active:
			swipe_stage = 1
	
	
	if use_controler:
		#Controler 2nd part
		#print(Input.get_joy_axis(0,2))
		piv.rotate_y(Input.get_joy_axis(0,2) * -mouse_sensitivity * delta * 1000)
		spring_arm.rotation.x =  lerp(spring_arm.rotation.x , (PI/2) * -Input.get_joy_axis(0,3), mouse_sensitivity * delta * 1000)

