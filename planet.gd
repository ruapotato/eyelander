extends Node3D

# Music paths
var bg_music = "res://import/CC-BY Kevin MacLeod/Kevin MacLeod - Nu Flute_edit.wav"
var fight_music = "res://import/CC BY Mystery Mammal/Mystery Mammal - Boss Battle.wav"

@onready var player = get_player()
@onready var terrain = $Terrain3D

func _ready():
	if !terrain:
		return
	# Initial camera setup
	var camera = find_player_camera()
	if camera:
		terrain.set_camera(camera)

func _process(_delta):
	if !terrain:
		return
		
	# Update camera every frame in case it changes
	var camera = find_player_camera()
	if camera:
		terrain.set_camera(camera)

func get_player():
	var root = get_tree().root
	return root.find_child("player", true, false)

func find_player_camera():
	# Look for camera in player's children
	if player:
		return player.find_child("Camera3D", true, false)
	return null
