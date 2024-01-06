extends AudioStreamPlayer3D

@onready var light = find_child("sound_light")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(get_playback_position())
	if get_playback_position() != 0:
		var this_stream = get_stream_playback()
		var volume_peak = AudioServer.get_bus_peak_volume_left_db(0,0)
		if volume_peak > -150:
			light.light_energy = abs(volume_peak)
			print(volume_peak)
	else:
		light.light_energy = 0

