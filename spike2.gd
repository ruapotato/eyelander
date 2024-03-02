extends Area3D

@onready var boss = get_parent().find_child("boss_3")

@onready var ring_x = $ring_x
@onready var ring_y = $ring_y
@onready var ring_z = $ring_z

var player
var damage = 1
var ttl = 4
var bad = true
var target = Vector3(0,0,0)
var speed = 13
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	#wadd_collision_exception_with(boss)
	pass # Replace with function body.

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ring_x.rotate_y(delta * 2.2)
	ring_y.rotate_x(delta * 2.4)
	ring_z.rotate_z(delta * 3)
	
	if bad:
		target = player.global_position
	else:
		target = boss.global_position + Vector3(0,1,0)
	
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
	#print(body.name)
	if body.name == "shild":
		queue_free()
	elif body.name == "player":
		if bad:
			print("hurt player")
			body.damage_todo += damage
	elif body.name == "boss_3":
		if not bad:
			print("hurt boss")
			body.damage_todo += damage
			queue_free()
	elif body.name != "sword" and body.name != "scythe":
		print("hit " + body.name)
		queue_free()


func _on_area_entered(area):
	_on_body_entered(area)
