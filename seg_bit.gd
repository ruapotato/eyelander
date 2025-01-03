extends Area3D
#@onready var player = get_parent().get_parent().find_child("player")
@onready var dirt_sounds = $walking_dirt
@onready var hurt_sund = $hurt
@onready var not_dead = true
@onready var animation_tree = find_child("mesh").find_child("AnimationTree")
@onready var bite_sound = $bite_sound
@onready var spawn_sound = get_parent().find_child("spawn")
var is_head = false
#var head_seg
var seg_index
var index
var life
var parent_seg = null
var circle_range = 3
var speed = 8
var head_hight = 2
var head_bob = 0
var setup = false
var sound_started = false
var level_edge = 35
var player_pass = false
var heading = Vector3(.3,0,0)
var knockback_strength = 40
var slam_damage = 50
var damage_todo = 0
var head_convert_counter = 1
var ground = 0
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	print(find_child("mesh").get_children())
	pass#heading = global_position.move_toward(get_target(), (speed) * .1)

func get_parent_seg():
	for body in get_parent().get_children():
		if body.name == parent_seg:
			if body.not_dead:
				return(body)
	return(false)

func walk_sound():

	var sound_to_use = dirt_sounds.get_children().pick_random()
	#var sound_to_use = dirt_sounds.get_children()[0]
	#$"sounds/walking_dirt/1/sound_light".light_energy
	#$"sounds/walking_dirt/1".
	sound_to_use.play()


func get_target():
	return(player.global_position + Vector3(0,.2,0))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if damage_todo != 0:
		print("Stuff hurt Yo")
		# Don't do damage when converting
		if head_convert_counter <= 0 or not is_head:
			if damage_todo > 15:
				hurt_sund.play()
			life -= damage_todo
		damage_todo = 0
		if life <= 0:
			print("Segment down!")
			not_dead = false
			#queue_free()
	
	if not not_dead:
		global_position.y = lerp(global_position.y, -1.0, .2)
		return
	head_bob += delta 
	if not setup and seg_index:
		setup = true
		head_bob -= seg_index * .1
	head_hight = ((head_bob - int(head_bob)) ) * 2
	
	if is_head and head_convert_counter > 0:
		head_convert_counter -= delta
		#print("HEADING " + str(head_convert_counter))
		animation_tree.set("parameters/BlendSpace1D/blend_position", head_convert_counter)
		return
		
	
	
	var speed_effector = head_hight * 2
	if speed_effector < .1:
		if not sound_started:
			walk_sound()
			sound_started = true
	else:
		sound_started = false
	if head_hight > 1:
		head_hight = 1 - (head_hight - 1)
		head_hight = head_hight * 4
	if is_head:
		global_position.y = lerp(global_position.y, head_hight + ground, 2 * delta)

		#retarget player
		if global_position.distance_to(Vector3(0,ground,0)) > level_edge:
			look_at(get_target())
			heading = global_position.move_toward(get_target(), (speed) * delta) - global_position

		global_position += (heading * speed_effector)
		
		#update start sound if needed
		if spawn_sound.playing:
			spawn_sound.global_position = global_position
			spawn_sound.global_position.y = ground + 1
	
	if not is_head:
		var pseg = get_parent_seg()
		if not pseg:
			is_head = true
			return
		look_at(pseg.global_position)
		global_position.y = lerp(global_position.y, head_hight + ground, 2 * delta)
		if global_position.distance_to(pseg.global_position) > $CollisionShape3D.shape.radius * 2:
			#global_position = lerp(global_position, pseg.global_position, speed * delta * 2)
			global_position = global_position.move_toward(pseg.global_position, (speed * 2) * delta)
			

		#print(parent_seg)


func _on_area_entered(area):
	_on_body_entered(area)


func _on_body_entered(body):
	if is_head:
		#print("Smaked your ass")
		var knockback_direction = global_position.direction_to(get_target())
		var knockback_force
		#player.set_deferred("velocity", player.velocity + knockback_force)
		if body.name == "shild":
			print("shild hit")
			knockback_force = knockback_direction  * (knockback_strength * .5)
			knockback_force.y = 2
			if player.dazzed == 0:
				animation_tree.set("parameters/bite/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				bite_sound.play()
				player.knockback = knockback_force
				player.damage_todo = 5
				body.find_child("hit").play()
		elif body.name == "player":
			print("player hit")
			animation_tree.set("parameters/bite/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			bite_sound.play()
			knockback_force = knockback_direction * knockback_strength
			knockback_force.y = 2
			if player.dazzed == 0:
				player.knockback = knockback_force
				player.damage_todo = slam_damage
