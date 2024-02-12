extends Node3D

@export var playing = false
# Called when the node enters the scene tree for the first time.
func _process(delta):
	if not playing and visible:
		visible = false
	if playing:
		$AnimationPlayer.play("swipping")
		#print(name)
		visible = true
