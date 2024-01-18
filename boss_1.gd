extends CharacterBody3D

@onready var sounds = $sounds
@onready var dirt_sounds = $sounds/walking_dirt
@onready var effect_sounds = $sounds/effects
@onready var slam_sound = $sounds/effects/slam
@onready var roar1_sound = $sounds/effects/roar
@onready var hurt_sound = $sounds/effects/hurt
@onready var player = get_parent().find_child("player")
@onready var armature = find_child("mesh").find_child("Armature")
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")
@onready var slam_effect = $slam_effect
@onready var butt = $butt
var walk_sound_every = 1000
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
var slam_damage = 50
var start_life = 1000
var life = start_life
var damage_todo = 0
var knockback = Vector3(0,0,0)
var dazzed = 0
var new_speed = Vector3(0,0,0)


var walking_on = "dirt"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#set_lock_rotation_enabled(true)

func slam():
	print("SLAM")
	slam_sound.play()
	#Effect
	slam_effect.find_child("slam_particles").emitting = true
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player < near:
		var space_state = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.new()
		
		ray_query.from = global_position
		ray_query.to = player.global_position
		ray_query.exclude = [get_rid()]
		#ray_query.collide_with_bodies = true
		#ray_query.collide_with_areas = true
		var hit = space_state.intersect_ray(ray_query)
		#print(hit)
		if not hit.is_empty():
			var knockback_direction = global_position.direction_to(player.global_position)
			var knockback_force
			#player.set_deferred("velocity", player.velocity + knockback_force)
			if hit.collider.name == "shild":
				print("shild hit")
				knockback_force = knockback_direction  * (knockback_strength * .5)
				knockback_force.y = 2
				player.knockback = knockback_force
				player.damage_todo = 5
			elif hit.collider.name == "player":
				print("player hit")
				knockback_force = knockback_direction * knockback_strength
				knockback_force.y = 2
				player.knockback = knockback_force
				player.damage_todo = slam_damage
		#		print(body)

func walk_sound():
	if walking_on == "dirt":
		#var sound_to_use = dirt_sounds.get_children().pick_random()
		var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()




func _physics_process(delta):
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
			$target.look_at(player.global_position, Vector3(0,1,0))
			global_rotation.y = lerp_angle(global_rotation.y, $target.global_rotation.y, .01)
			
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_sounds_timer = 0
		if action != "walking":
			new_speed.x = lerp(new_speed.x, 0.0, .2)
			new_speed.z = lerp(new_speed.z, 0.0, .2)
	
	
	
		#print(sword.rotation.y)
	velocity = new_speed
	move_and_slide()





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if damage_todo != 0:
		hurt_sound.play()
		life -= damage_todo
		damage_todo = 0
		#print(life)
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	walk_sound_every = velocity.length() * delta * 50
	#print(walk_sound_every)

	var dist_to_player = global_position.distance_to(player.global_position)
	#print(dist_to_player)
	if dist_to_player < near:
		action = "slaming"
	else:
		action = "walking"
	
	if slam_started:
		slam_count_down -= delta
		if slam_count_down <= 0:
			slam_started = false
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
