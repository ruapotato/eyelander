extends CharacterBody3D

@onready var sounds = $sounds
@onready var dirt_sounds = $sounds/walking_dirt
@onready var player = get_parent().find_child("player")
@onready var armature = find_child("mesh").find_child("Armature")
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")
var walk_sound_every = 1000
var walk_sounds_timer = 0
var SPEED = 2
var MAX_SPEED = 2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var action = "walking"
var near = 7.5
var slam_started = false
var slam_time = 1.6
var slam_count_down = 0


var walking_on = "dirt"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#set_lock_rotation_enabled(true)


func slam():
	print("SLAM")


func walk_sound():
	if walking_on == "dirt":
		#var sound_to_use = dirt_sounds.get_children().pick_random()
		var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
			slam_started = true
			animation_tree.set("parameters/slam/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	
	if action == "walking":
		var input_dir = Vector3(0,-1,0)
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		#print(armature)
		#armature.look_at(player.global_position, Vector3(0,1,0))
		look_at(player.global_position, Vector3(0,1,0))
		walk_sounds_timer += delta
		if walk_sounds_timer >= walk_sound_every:
			walk_sound()
			walk_sounds_timer = 0
	animation_tree.set("parameters/moving/blend_position", velocity.length() * MAX_SPEED)
	move_and_slide()
	#armature.rotation.y = atan2(-player.global_position.x, -player.global_position.z)
	#armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-player.global_position.x, -player.global_position.z), .2)
	#rotation.y = lerp_angle(rotation.y, atan2(-player.global_position.x, -player.global_position.z), .2)
