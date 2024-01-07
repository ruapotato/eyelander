extends RigidBody3D

@onready var sounds = $sounds
@onready var dirt_sounds = $sounds/walking_dirt

var walk_sound_every = randi() % 3
var walk_sounds_timer = 0

var walking_on = "dirt"
# Called when the node enters the scene tree for the first time.
func _ready():
	set_lock_rotation_enabled(true)



func walk_sound():
	if walking_on == "dirt":
		#var sound_to_use = dirt_sounds.get_children().pick_random()
		var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	walk_sounds_timer += delta
	if walk_sounds_timer >= walk_sound_every:
		walk_sound()
		walk_sounds_timer = 0
