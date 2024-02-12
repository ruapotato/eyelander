extends Area3D

@onready var swing_sound = $swing
@onready var hit_sound = $hit
@onready var r_hand_bone
@onready var player = get_parent()

var init_pos
var init_rot
var knockback_strength = 10
var damage = 50.0
var jump_damage = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	#contact_monitor = true
	#max_contacts_reported = 1000000
	init_pos = position
	init_rot = rotation
	#axis_lock_angular_x = true
	#axis_lock_angular_z = true
	#axis_lock_angular_y = true
	#axis_lock_linear_x = true
	#axis_lock_linear_y = true
	#axis_lock_linear_z = true
	#add_collision_exception_with(get_parent())
	#add_collision_exception_with(get_parent().find_child("shild"))

func _integrate_forces(state):
	pass
	#if rotation != init_rot:
	#	if get_contact_count() == 0:
			#rotation = lerp(rotation, init_rot, .15)
	#		pass
	#if position != init_pos:
	#	if get_contact_count() == 0:
	#		pass
			#position = lerp(position, init_pos, .15)
			#apply_impulse()
			#position = init_pos
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.right_hand_bone:
		global_position = player.right_hand_bone.global_position
		global_rotation = player.right_hand_bone.global_rotation
		#print(player.right_hand_bone)

		
func get_target():
	return(get_parent().get_parent().find_child("boss_1").global_position + Vector3(0,.5,0))

func get_damage():
	if not get_parent().is_on_floor():
		return(get_parent().velocity.length() * jump_damage)
	else:
		if swing_sound.playing:
			return(randi_range(damage, damage * 2))
		else:
			return(0)

func _on_body_entered(body):
	if get_parent().dead:
		return
	var hit_damage = get_damage()
	if hit_damage == 0:
		return
	#print( body.name)
	if "spike" in body.name:
		if body.bad:
			if swing_sound.playing:
				body.target = get_target()
				body.ttl = 4
				#print("Spike hit!!!")
				body.bad = false
	if "segy" in body.name:
		body.damage_todo += get_damage()
	
	if body.name == "boss_3":
		if body.dazzed == 0:
			body.damage_todo += get_damage()
			var knockback_direction = global_position.direction_to(body.global_position)
			var knockback_force
			#player.set_deferred("velocity", player.velocity + knockback_force)
			#print("boss hit")
			knockback_force = knockback_direction * knockback_strength * 3
			knockback_force.y = 5
			body.knockback = knockback_force
	
	
	if body.name == "butt":
		
		if hit_damage > 0:
			body.get_parent().damage_todo += hit_damage
			
			var knockback_direction = global_position.direction_to(body.global_position)
			var knockback_force
			#player.set_deferred("velocity", player.velocity + knockback_force)
			#print("boss hit")
			knockback_force = knockback_direction * knockback_strength
			knockback_force.y = 5
			body.get_parent().knockback = knockback_force
	else:
		if body.name != "shild":
			hit_sound.play()


func _on_area_entered(area):
	_on_body_entered(area)
