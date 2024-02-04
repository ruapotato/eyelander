extends Area3D

@onready var boss = get_parent().find_child("boss_4")
@onready var player = get_parent().find_child("player")
var damage = 33
var ttl = 5
var bad = true
var target = Vector3(0,0,0)
var speed = 8
var size = 1
var grow_at = .5
var knockback_strength = 20
# Called when the node enters the scene tree for the first time.
func _ready():
	target = get_parent().find_child("t_target").global_position
	target.y = player.global_position.y - .35
	#wadd_collision_exception_with(boss)
	pass # Replace with function body.



func _process_push(delta):
	#var space_state = get_world_3d().direct_space_state
	#var ray_query = PhysicsRayQueryParameters3D.new()
	var dist_to_player = global_position.distance_to(player.global_position)
	#ray_query.from = global_position
	#ray_query.to = target
	#ray_query.exclude = [get_rid(), boss.get_rid()]
	#ray_query.collide_with_bodies = true
	#ray_query.collide_with_areas = true
	#var hit = space_state.intersect_ray(ray_query)
	#print(hit)
	#if not hit.is_empty():
		
	var wind_direction = global_position.direction_to(player.global_position)
	var wind_force
	wind_force = wind_direction  * knockback_strength
	#wind_force.y =  wind_force.length()
	wind_force.y = clamp(abs(wind_force.y),0.0,5)
	wind_force = wind_force  / (dist_to_player * 3)
	player.wind = wind_force
	#print()
	#print(dist_to_player)
	#print(player.wind.length())
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_process_push(delta)
	$MeshInstance3D.rotate_y(delta * 10)
	global_position.y = lerp(global_position.y, target.y, delta * 5)
	size += delta * grow_at
	#print(scale)
	scale = Vector3(size,size,size)
	#if bad:
	#else:
	#	target = boss.global_position + Vector3(0,1,0)
	
	if global_position != target:
		look_at(target)
	#global_position = lerp(global_position, target, delta * speed)
	
	global_position = global_position.move_toward(target, delta * speed)

	#if global_position == target:
	#	queue_free()
	ttl -= delta
	if ttl < 0:
		queue_free()

func _on_body_entered(body):
	return
	#print(body.name)
	if body.name == "shild":
		queue_free()
	elif body.name == "player":
		if bad:
			print("hurt player")
			body.damage_todo += damage
	elif body.name == "boss_1":
		if not bad:
			print("hurt boss")
			body.damage_todo += damage
			queue_free()
	elif body.name != "sword":
		print("hit " + body.name)
		queue_free()


func _on_area_entered(area):
	_on_body_entered(area)
