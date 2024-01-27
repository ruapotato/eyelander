extends CharacterBody3D

@onready var sounds = $sounds
@onready var dirt_sounds = $sounds/walking_dirt
@onready var effect_sounds = $sounds/effects
@onready var slam_sound = $sounds/effects/slam
@onready var roar1_sound = $sounds/effects/roar
@onready var hurt_sound = $sounds/effects/hurt
@onready var hurt2_sound = $sounds/effects/hurt2
@onready var fly_sound = $sounds/effects/fly
@onready var player = get_parent().find_child("player")
@onready var armature = find_child("mesh").find_child("Armature")
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")
@onready var butt_bone = find_child("mesh").find_child("butt_bone")
@onready var head_bone = find_child("mesh").find_child("head_bone")
@onready var brain_bone = find_child("mesh").find_child("brain_bone")
#@onready var slam_effect = $slam_effect
@onready var slam_effect = preload("res://slam_effect.tscn")
@onready var butt = $butt
@onready var head = $head
@onready var spawn_next = preload("res://end_screen.tscn")
@onready var spike = preload("res://spike.tscn")

var life_gen = 2
var walk_sound_every = 0
var walk_sounds_timer = 0
var SPEED = 2
var MAX_SPEED = 2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var action = "walking"
var near = 8
var slam_started = false
var slam_time = 1.6
var slam_count_down = 0
var knockback_strength = 25
var slam_damage = 33
var start_life = 500
#var start_life = 20
var life = start_life
var damage_todo = 0
var knockback = Vector3(0,0,0)
var dazzed = 0
var new_speed = Vector3(0,0,0)
var dead = false
var hover_level = 5.0

var stage = 1
var start_stage_2 = start_life/2
var fire_rate = 2
var fire_counter = fire_rate
var target = Vector3(0,0,0)
var spike_count = 0
var rage_time = 6.5
var rage_counter = 0
var can_rage = true

var walking_on = "dirt"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#set_lock_rotation_enabled(true)

func slam():
	#print("SLAM")
	slam_sound.play()
	#Effect
	var new_slam_effect = slam_effect.instantiate()
	var slam_pos = head_bone.global_position
	slam_pos.y = 0
	new_slam_effect.set_deferred("global_position", slam_pos)
	
	if animation_tree.get("parameters/fly/active"):
		animation_tree.set("parameters/fly/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	# Handle Jump.
	#slam_effect.global_position = 
	#slam_effect.find_child("slam_particles").time = 0
	new_slam_effect.find_child("slam_particles").emitting = true
	get_parent().add_child(new_slam_effect)
	var dist_to_player = slam_pos.distance_to(get_target())
	if dist_to_player < near:
		var space_state = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.new()
		
		ray_query.from = slam_pos
		ray_query.to = get_target()
		ray_query.exclude = [get_rid()]
		#ray_query.collide_with_bodies = true
		#ray_query.collide_with_areas = true
		var hit = space_state.intersect_ray(ray_query)
		#print(hit)
		if not hit.is_empty():
			var knockback_direction = global_position.direction_to(get_target())
			var knockback_force
			if player.dazzed == 0:
				#player.set_deferred("velocity", player.velocity + knockback_force)
				if hit.collider.name == "shild":
					#print("shild hit")
					knockback_force = knockback_direction  * (knockback_strength * .5)
					knockback_force.y = 2
					player.knockback = knockback_force
					player.damage_todo = 5
					hit.collider.find_child("hit").play()
				elif hit.collider.name == "player":
					#print("player hit")
					knockback_force = knockback_direction * knockback_strength
					knockback_force.y = 2
					player.knockback = knockback_force
					player.damage_todo = slam_damage
			#		print(body)

func walk_sound():
	if walking_on == "dirt":
		var sound_to_use = dirt_sounds.get_children().pick_random()
		#var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()


func fire_spike():
	spike_count += 1
	var new_spike = spike.instantiate()
	#new_spike.add_collision_exception_with(self)
	#new_spike.contact_monitor = true
	#new_spike.linear_velocity = Vector3(1,0,0)
	#var local_target = Vector3(0,0,- 1)
	new_spike.target = get_target()
	#var global_direction = -$target.global_transform.basis.z * 10
	#new_spike.linear_velocity = global_direction
	new_spike.set_deferred("global_position", $target.global_position)
	#new_spike.set_deferred("global_rotation", $target.global_rotation)
	new_spike.name = "spike_" + str(spike_count)
	#new_spike.global_position = $target.global_position
	get_parent().add_child(new_spike)

func get_target():
	return(player.global_position + Vector3(0,.2,0))

func get_head_pos():
	return(brain_bone.global_position - Vector3(0,2,0))


func _physics_process(delta):
	if dead:
		return
	head.global_position = get_head_pos() 
	head.global_rotation = brain_bone.global_rotation
	
	butt.global_position = butt_bone.global_position
	butt.global_rotation = butt_bone.global_rotation
	new_speed = velocity
	if knockback != Vector3(0,0,0):
		dazzed = knockback.length() / 50
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
	
	
	if action == "flying":
		if fire_counter > 0:
			fire_counter -= delta
		else:
			#print("FIRE")
			fire_spike()
			fire_counter = fire_rate
		$target.look_at(get_target(), Vector3(0,1,0))
		global_rotation.y = lerp_angle(global_rotation.y, $target.global_rotation.y, .02)
		if global_position.y < hover_level:
			global_position.y = lerp(global_position.y, hover_level, .05)
			new_speed.y = 0
		if slam_count_down < 0:
			slam_count_down = 0
		if animation_tree.get("parameters/rage/active"):
			animation_tree.set("parameters/rage/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		if not animation_tree.get("parameters/fly/active"):
			animation_tree.set("parameters/fly/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			
		if not fly_sound.playing:
				fly_sound.play()
	
	if action != "flying":
		if fly_sound.playing:
				fly_sound.stop()
	# Handle Jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
	#	new_speed.y += JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if dazzed == 0:
		if action == "walking" and not animation_tree.get("parameters/slam/active"):
			var input_dir = Vector3(0,-1,0)
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			new_speed.x = lerp(new_speed.x, direction.x * SPEED, .2)
			new_speed.z = lerp(new_speed.z, direction.z * SPEED, .2)
			$target.look_at(get_target(), Vector3(0,1,0))
			global_rotation.y = lerp_angle(global_rotation.y, $target.global_rotation.y, .01)
			
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_sounds_timer = 0
				#print("wlak sound")
		if action != "walking":
			new_speed.x = lerp(new_speed.x, 0.0, .2)
			new_speed.z = lerp(new_speed.z, 0.0, .2)
	
	
	
		#print(sword.rotation.y)
	if dazzed:
		$target.look_at(get_target(), Vector3(0,1,0))
		global_rotation.y = lerp_angle(global_rotation.y, $target.global_rotation.y, .2)
	
	velocity = new_speed
	move_and_slide()





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		rotation.z = lerp(rotation.z, 3.0, .01)
		position.y = lerp(position.y, -2.0, .001)
		return
	if damage_todo != 0:
		# If hurt while raging, rage more
		if rage_counter != 0:
			rage_counter = rage_time
			#damage_todo = 0
		can_rage = true
		life -= damage_todo
		if life > 0:
			hurt_sound.play()
		damage_todo = 0
	if life <= 0 and not dead:
			#print("Boss dead")
			#Remove bits we don't need anymore
			butt.queue_free()
			$pinchers.queue_free()
			$head.queue_free()
			
			#open next level
			get_parent().find_child("1_level_plug").queue_free()
			get_parent().find_child("1_level_light").play()
			
			#Setup player data
			player.level = 2
			player.boss = player.boss_2
			
			hurt2_sound.play()
			dead = true
	if life < start_life:
		if rage_counter == 0:
			life += delta * life_gen
	#if life < start_stage_2:
	#	stage = 2
	sounds.global_position = butt_bone.global_position
	#stage = (int(life/10) % 2) + 1
	stage = (int(life/8) + 1)%3 + 1
	if stage == 3:
		if int(life) % 2 != 0:
			stage = 1
	#print(stage)
		#print(life)
	# Add the gravity.git status

	if not is_on_floor() and action != "flying":
		velocity.y -= gravity * delta
	walk_sound_every = 1/(velocity.length()*2)
	#print(walk_sound_every)

	var dist_to_player = global_position.distance_to(get_target())
	#print(dist_to_player)
	

	if stage == 3 and not slam_started:
		if can_rage:
			#print("start")
			action = "rage"
			rage_counter = rage_time
			can_rage = false
			animation_tree.set("parameters/rage/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		elif rage_counter > 0:
			rage_counter -= delta
		elif rage_counter < 0:
			rage_counter = 0
		else:
			stage = 1
			#print("Force starge 1")
	
	if stage == 1:
		if dist_to_player < near:
			action = "slaming"
		else:
			action = "walking"
	
	if stage == 2 and not slam_started:
		action = "flying"
	
	
	if slam_started:
		slam_count_down -= delta
		if slam_count_down <= 0:
			slam_started = false
			slam()
	
	if rage_counter > 0:
		if int(rage_counter * 10) % 4 == 0:
			#print("Range")
			slam()
	
	if action == "slaming":
		if not animation_tree.get("parameters/slam/active"):
			slam_count_down = slam_time
			roar1_sound.play()
			slam_started = true
			animation_tree.set("parameters/slam/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	animation_tree.set("parameters/moving/blend_position", velocity.length() * MAX_SPEED)
		
	#armature.rotation.y = atan2(-player.global_position.x, -player.global_position.z)
	#armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-player.global_position.x, -player.global_position.z), .2)
	#rotation.y = lerp_angle(rotation.y, atan2(-player.global_position.x, -player.global_position.z), .2)
