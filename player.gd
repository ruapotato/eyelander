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
@onready var boss = get_parent().find_child("boss_1")
@onready var boss_2 = get_parent().find_child("boss_2")
@onready var game_over_screen = preload("res://game_over.tscn")
var walk_sound_every = 0
var walk_sounds_timer = 0
var walking_on = "dirt"
var dead = false

var mouse_sensitivity = .0035
#var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 15
var SPEED = 5.0

var level = 1
var swipping = false
var swipe_speed = .2
var swipe_counter = 0
var damage_todo = 0
var life = 100
var life_gen = .5
var boss_life = 0
#var swipe_start_angle = 180
#var swipe_end_angle = 30
var swipe_stage = 1

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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		#rotate_x(event.relative.y * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
		#rotation.x = clamp(rotation.x, -PI/2, PI/2)
		
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		
	if Input.is_action_just_pressed("swipe"):
		swipping = true
		swipe_counter = swipe_speed
		swipe_stage += 1
		if swipe_stage > len(swipe_angles):
			swipe_stage = 1

		
		if not shilding:
			if not sword.find_child("swing").playing:
				sword.find_child("swing").play()
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
				walk_sounds_timer = 0
			#print("wlak sound")
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (piv.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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

	
	if shilding:
		# Set shilding pos
		shild.rotation_degrees.y = lerp(shild.rotation_degrees.y, shilding_angle + piv.rotation_degrees.y, .2)
		# Set camera 
		#shild.rotation_degrees.x = spring_arm.rotation_degrees.x
		# Set sword pos
		sword.rotation_degrees.y = piv.rotation_degrees.y - 100
	if not shilding:
		shild.rotation_degrees.y = shild_hold_angle + piv.rotation_degrees.y
	
	
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
			
			if  is_equal_approx(sword.rotation.z, 1.5):
				sword.rotation.x = lerp(sword.rotation.x ,spring_arm.rotation.x * -1, .2)
	if (not swipping or swipe_done) and not shilding:
		#sword.rotation.y = lerp_angle(sword.rotation.y, atan2(-direction.x, -direction.z), .2)
		#if not Input.is_action_pressed("swipe"):
		sword.rotation_degrees.y = sword_hold_angle + piv.rotation_degrees.y 
		sword.rotation.z = 0
		sword.rotation.x = 0
		
		#print(sword.rotation.y)
	velocity = new_speed
	move_and_slide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if boss_life != boss.life:
		boss_life = boss.life
		if gui.find_child("BOSS_LIFE"):
			gui.find_child("BOSS_LIFE").value = (boss.life/boss.start_life) * 100
			print(gui.find_child("BOSS_LIFE").value)
		print(gui.find_child("BOSS_LIFE"))
		
	
	if life < 100:
		life += delta * life_gen
		gui.find_child("LIFE").value = life
	elif life > 100:
		life = 100
	
	if damage_todo != 0:
		if damage_todo > 15:
			hurt_sund.play()
		life -= damage_todo
		gui.find_child("LIFE").value = life
		damage_todo = 0
		if life <= 0:
			print("You are dead")
			var RIP = game_over_screen.instantiate()
			get_parent().add_child(RIP)
			dead = true
			#get_tree().reload_current_scene()
		#print(life)
