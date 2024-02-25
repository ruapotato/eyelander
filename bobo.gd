extends Node3D

@onready var gem_bone = find_child("mesh").find_child("gem_bone")
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")
@onready var spore = preload("res://spore_drop.tscn")
@onready var gem = $gem_bad_npc
@onready var eat_sound = $eat

var player
var range = 1
var snap_countdown = .2
var can_snap_player = false
var player_stuck = false
var stuck_for = 1.5
var stuck_counter = 0
var life = 3
var damage_todo = 0
var can_be_hurt = true
var dead = false


func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(can_be_hurt)
	if damage_todo != 0:
		#if not animation_tree.get("parameters/hurt/active"):
		#	if not animation_tree.get("parameters/bite/active"):
		life -= damage_todo
		if life > 0:
			animation_tree.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			can_be_hurt = false
			$hert.play()
		damage_todo = 0
	if life <= 0:
		if not dead:
			animation_tree.set("parameters/die/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			$die_sound.play()
			$gem_bad_npc/CollisionShape3D.queue_free()
			can_be_hurt = false
			dead = true
		elif not animation_tree.get("parameters/die/active"):
			queue_free()
		
	if stuck_counter >= 0:
		stuck_counter -= delta
	gem.global_position = gem_bone.global_position
	if snap_countdown > -1:
		snap_countdown -= delta
	if snap_countdown < -.2:
		can_snap_player = false
	
	if player_stuck:
		if stuck_counter <= 0:
			player_stuck = false
			#can_be_hurt = true
		else:
			player.velocity = Vector3(0,0,0)
			player.new_speed = Vector3(0,0,0)
			player.dazzed = .05
	if not can_be_hurt:
		if not animation_tree.get("parameters/hurt/active"):
			if not animation_tree.get("parameters/bite/active"):
				if not animation_tree.get("parameters/die/active"):
					can_be_hurt = true
	if global_position.distance_to(player.global_position) < range:
		if not animation_tree.get("parameters/bite/active"):
			animation_tree.set("parameters/bite/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			can_be_hurt = false
			eat_sound.play()
			snap_countdown = .2
			can_snap_player = true

		if snap_countdown < 0 and can_snap_player:
			print("Yo Stuck")
			if player_stuck == false:
				player.damage_todo = 1
			player_stuck = true
			can_be_hurt = false
			stuck_counter = stuck_for

