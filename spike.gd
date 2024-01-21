extends RigidBody3D

@onready var boss = get_parent().find_child("boss_1")
var damage = 10
var ttl = 4
# Called when the node enters the scene tree for the first time.
func _ready():
	add_collision_exception_with(boss)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ttl -= delta
	if ttl < 0:
		queue_free()

func _on_body_entered(body):
	print(body.name)
	if body.name == "player":
		print("hurt player")
		body.damage_todo += damage
