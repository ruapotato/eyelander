extends Node3D

var message = null
var message_range = 3

var player
var skin_mesh

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "World":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	#Hid unneded meshes
	for mesh in $Armature/Skeleton3D.get_children():
		if mesh.name != name:
			mesh.visible = false
		else:
			skin_mesh = mesh
	
	var outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(0,0,0)
	outline_material.metallic = .75
	outline_material.roughness = .07
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	#outline_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_material.grow = true
	outline_material.grow_amount = .01
	
	#This works but will grump at you TODO find a way to find number of materials an object has
	var i = 0
	while skin_mesh.get_active_material(i):
		skin_mesh.get_active_material(i).next_pass = outline_material
		#skin_mesh.get_active_material(i).roughness = .2
		skin_mesh.get_active_material(i).diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		skin_mesh.get_active_material(i).specular_mode = BaseMaterial3D.SPECULAR_TOON
		i = i + 1
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(player.global_position) < message_range:
		if message:
			player.message_ui = message
