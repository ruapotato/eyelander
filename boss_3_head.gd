extends Area3D

@onready var laser_l = $laser_l 
@onready var laser_r = $laser_r 
@onready var player = get_parent().get_parent().find_child("player")

var mounted = true
var was_mounted = true
var mounted_pos
var pop_off_pos
var pop_off_for = 17
var pop_off_counter = 0
var local_pop_off
var damage = 25
var knockback_force
var knockback_strength = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	mounted_pos = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if pop_off_counter > 0:
		pop_off_counter -= delta
	
	if not mounted and was_mounted:
		print("pop off")
		pop_off_pos = global_position
		local_pop_off = position
		was_mounted = false
	elif not was_mounted and mounted and pop_off_counter < 0:
		print("pop on")
		was_mounted = true
		
	if not mounted:

		#print(pop_off_counter)
		
		if pop_off_counter < 0:
			mounted = true
			print("HEAD MOUNTED")
		else:
			
			#Move fast on z
			global_position.y = lerp(global_position.y, pop_off_pos.y - 1.5, .2)
			rotate_y(delta * 1.5)
			#Start laser at center
			if global_position.distance_to(Vector3(0,pop_off_pos.y - 1.5,0)) < 1:
				laser_l.visible = true
				laser_r.visible = true
				if not laser_l.find_child("on_sound").playing:
					laser_l.find_child("on_sound").playing = true
				if not laser_r.find_child("on_sound").playing:
					laser_r.find_child("on_sound").playing = true
				
				pop_off_counter -= delta
			else:
				# Move to center
				global_position = lerp(global_position, Vector3(0,pop_off_pos.y - 1.5,0), .01)
	if mounted:
		$laser_l.visible = false
		$laser_r.visible = false
		position = lerp(position, mounted_pos, delta * 2)
		rotation = lerp(rotation, Vector3(0,0,0), delta * 2)


func _on_body_entered(body):
	if $laser_l.visible:
		if body.name == "player":
			print("hurt player with laser!")
			body.damage_todo += damage
			var knockback_direction = global_position.direction_to(body.global_position)
			var knockback_force
			#player.set_deferred("velocity", player.velocity + knockback_force)
			#print("boss hit")
			knockback_force = knockback_direction * (knockback_strength/2)
			knockback_force.y = 5
			body.knockback = knockback_force

