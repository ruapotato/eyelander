extends CharacterBody3D

@onready var spring_arm = $piv/SpringArm3D
@onready var piv = $piv
@onready var mesh = $mesh
@onready var sword_l1 = null
@onready var shield_l1 = null
@onready var camera = $piv/SpringArm3D/Camera3D
@onready var gui = $GUI
@onready var hurt_sund = $hurt
@onready var dirt_sounds = $sounds/walking_dirt
@onready var collisionshape = $CollisionShape3D
@onready var boss = get_parent().find_child("boss_1")
@onready var boss_2 = get_parent().find_child("boss_2")
@onready var boss_3 = get_parent().find_child("boss_3")
@onready var gui_compost = gui.find_child("compost")
@onready var game_over_screen = preload("res://game_over.tscn")
@onready var shield_1 = preload("res://shield.tscn")
@onready var sword_1 = preload("res://sword.tscn")
@onready var root = get_parent().get_parent()
@onready var animation_tree = get_node("mesh/AnimationTree")
@onready var right_hand_bone = get_node("mesh/Armature/Skeleton3D/right_hand")
@onready var left_hand_bone = get_node("mesh/Armature/Skeleton3D/left_hand")
@onready var swipe_1_effect = $CollisionShape3D/swipes/swipe_1
@onready var swipe_2_effect = $CollisionShape3D/swipes/swipe_2
@onready var swipe_3_effect = $CollisionShape3D/swipes/swipe_3
@onready var jump_swipe_effect = $CollisionShape3D/swipes/jump_swipe
@onready var camera_look_target = $piv/SpringArm3D/camera_look_target
@onready var message_box = $GUI/MESSAGE
@onready var message_warning = $GUI/MESSAGE_WARNING
@onready var message_bg = $GUI/MESSAGE_BG

var inventory = null
var look_at_override = null
var message_options = null
var save_index = null
var gender = null
var player_picked_name = null
var in_menu = false
var heal_started = false
var swimming = false
var swim_up_speed = 5
var swim_bob_level = 0
var swim_walk_flip = 0.0

var _save_file = null
var message_index = -1
var message_option_index = 1
var message_ui = null
var needs_to_load = null
var total_swipe_stages = 3
var swipe_stage = 1
var walk_sound_every = 0
var walk_sounds_timer = 0
var walking_on = "dirt"
var dead = false
var wind = Vector3(0,0,0)
var max_zoom = 4.75
var min_zoom = -.25
var mini_map_cam_height = 30
var max_compost = 3
var compost = 3
var heal_speed = 2
var heal_count_down = 0
var cast_cool_down_time = .35
var cast_cool_down = 0

var mouse_sensitivity = .0035
#var speed = 5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var JUMP_VELOCITY = 15
var SPEED = 5.0

var level = 1
var swipping = false
var swipe_speed = .3
var swipe_counter = 0
var damage_todo = 0
var start_life = 3
var life = start_life
var life_gen = .5
var boss_life = 0
#var swipe_start_angle = 180
#var swipe_end_angle = 30


#var sword_hold_angle = 123
#var sword_center_angle = 180
#var sword_far_left_angle = 250
#var swipe_angles = {1: [sword_hold_angle, sword_far_left_angle],
#					2: [sword_far_left_angle,sword_hold_angle]}
#					3: [sword_hold_angle, sword_far_left_angle]}

var shielding = false
var backpack_slots 
var shield_hold_angle = 90
var shielding_angle = 0
var knockback = Vector3(0,0,0)
var dazzed = 0
var new_speed = Vector3(0,0,0)
var og_camera_angle
var shake = 0
var walk_shake = 0
var has_won = false
var effects_effector
var use_controler = false
var acton_name
var mid_jump_swipe = false
var jump_swipe_added = false
var jump_swipe_dir = Vector3(0,.4,-1)
var jump_swipe_speed = 20

var mid_backflip = false
var backflip_added = true
var backflip_dir = Vector3(0,.3,1)
var backflip_speed = 30


var mid_sidejump = false
var sidejump_added = true
var sidejump_dir_l = Vector3(-1,.3,0)
var sidejump_dir_r = Vector3(1,.3,0)
var sidejump_speed = 30
var pause_menu
var mini_map_cam
var test_sword  = {"name": "sword_l1", "scene": "res://sword.tscn",  "icon": "res://import/CC0 by Henrique Lazarini, 7Soul1/edits/WWW_killer.png", "count": 1, "max_count": 1, "handed": "right", "equipped": false}
var test_shield = {"name": "shield_l1", "scene": "res://shield.tscn","icon": "res://import/CC0 by Henrique Lazarini, 7Soul1/edits/Shield.png", "count": 1, "max_count": 1, "handed": "left", "equipped": false}
#var empty_items = [[test_sword,test_shield,{},{},{}],
"""
var empty_items = [[{},{},{},{},{}],
[{},{},{},{},{},{},{},{},{},{}],
[{},{},{},{},{},{},{},{},{},{}],
[{},{},{},{},{},{},{},{},{},{}],
[{},{},{},{},{},{},{},{},{},{}],
[{},{},{},{},{},{},{},{},{},{}]]
"""
var items
var blank_item = {"name": "", "equipped": false}
var left_hand_item = blank_item
var right_hand_item = blank_item

# Called when the node enters the scene tree for the first time.
func _ready():
	mini_map_cam = gui.find_child("mini_map_cam")
	pause_menu = gui.find_child("pause_menu")
	backpack_slots = gui.find_child("backpack_slots")
	spring_arm.add_excluded_object(self)
	og_camera_angle = camera.rotation_degrees
	start_life = start_life / get_parent().hardness
	life_gen = life_gen / get_parent().hardness
	life = start_life
	
	acton_name = "parameters/swipe_" + str(swipe_stage)
	#Setup mouse settins
	if root.mouse_sensitivity_effector > 0:
		for i in range(0, int(root.mouse_sensitivity_effector)):
			mouse_sensitivity *= 1.2
	elif  root.mouse_sensitivity_effector < 0:
		for i in range(0, int(abs(root.mouse_sensitivity_effector))):
			mouse_sensitivity *= .8
	
	#Setup effects
	effects_effector = root.effects_effector
	
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
	
	
	var skin_mesh
	#load save
	save_index = get_parent().game_index
	_save_file = "user://savegame_" + str(save_index) + ".json"
	inventory = load_save(_save_file)
	var gender = inventory['gender']
	var player_picked_name = inventory['name']
	items = inventory['menu_items']
	#if items in inventory:
	#	items = inventory["items"]
	#else:
	#	items = empty_items
	gui.draw_items(items)
	# Setup possable inventory items
	#if inventory["sword"] == 1:
	#sword_l1 = sword_1.instantiate()
	#add_child(sword_l1)
	#if inventory["shield"] == 1:
	#shield_l1 = shield_1.instantiate()
	#add_child(shield_l1)
	
	if gender == "male":
		mesh.find_child("Briska").visible = false
		mesh.find_child("island_male_1").visible = true
		skin_mesh = mesh.find_child("island_male_1")
	else:
		mesh.find_child("Briska").visible = true
		mesh.find_child("island_male_1").visible = false
		skin_mesh = mesh.find_child("Briska")
	
	
	#This works but will grump at you TODO find a way to find number of materials an object has
	var i = 0
	while skin_mesh.get_active_material(i):
		skin_mesh.get_active_material(i).next_pass = outline_material
		#skin_mesh.get_active_material(i).roughness = .2
		skin_mesh.get_active_material(i).diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		skin_mesh.get_active_material(i).specular_mode = BaseMaterial3D.SPECULAR_TOON
		i = i + 1
	
	#setup life
	hide_unused_life()
	
	#print(effects_effector)


func hide_unused_life():
	for obj in gui.get_children():
		if "LIFE_" in obj.name:
			var index = int(obj.name.split("_")[-1])
			
			if index <= start_life:
				obj.visible = true
				print("INDEX: " + str(index))
			else:
				obj.visible = false

func update_life():
	for obj in gui.get_children():
		if "LIFE_" in obj.name:
			var index = int(obj.name.split("_")[-1])
			if index <= start_life:
				if index <= life:
					print("Life on: " + str(index))
					obj.modulate = Color("#ffffff")
				else:
					print("Life off: " + str(index))
					obj.modulate = Color("#000000")

func load_save(save_file):
	var save_game = FileAccess.open(save_file, FileAccess.READ)
	var json_string = save_game.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	print(parse_result)
	if parse_result == 0:
		var save_data = json.get_data()
		return(save_data)

func _save_game():
	var save_game = FileAccess.open(_save_file, FileAccess.WRITE)
	var save_data = JSON.stringify({"gender":gender,
	"name":player_picked_name})
	save_game.store_line(save_data)


func select_slot(slot_index):
	slot_index -= 1
	if items[0][slot_index] and "scene" in items[0][slot_index]:
		var slot_item = items[0][slot_index]
		var slot_scene = load(slot_item["scene"])
		if slot_item["handed"] == "right":
			if right_hand_item.name != blank_item.name:
				right_hand_item.queue_free()
				right_hand_item = blank_item
				items[0][slot_index]["equipped"] = false
			else:
				right_hand_item = slot_scene.instantiate()
				add_child(right_hand_item)
				items[0][slot_index]["equipped"] = true
		if slot_item["handed"] == "left":
			if left_hand_item.name != blank_item.name:
				left_hand_item.queue_free()
				left_hand_item = blank_item
				items[0][slot_index]["equipped"] = false
			else:
				left_hand_item = slot_scene.instantiate()
				add_child(left_hand_item)
				items[0][slot_index]["equipped"] = true
	gui.draw_items(items)

func _unhandled_input(event):
	#if Input.is_action_just_pressed("quit"):
	#	get_tree().quit()
	if Input.is_action_just_pressed("inventory"):
		backpack_slots.visible = !backpack_slots.visible
		in_menu =  backpack_slots.visible 
		if in_menu:
			Engine.time_scale = 0.5
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Engine.time_scale = 1.0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("pause"):
		pause_menu.visible = !pause_menu.visible
		in_menu = pause_menu.visible 
		if in_menu:
			Engine.time_scale = 0.0
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Engine.time_scale = 1.0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if in_menu:
		return
	
	if Input.is_action_just_pressed("interact"):
		# Update message box page
		if message_ui:
			message_index += 1
			if len(message_ui) > message_index:
				message_box.text = message_ui[message_index]
				message_box.visible = true
				message_bg.visible = true
			else:
				message_box.visible = false
				message_bg.visible = false
				message_index = -1
	
	if Input.is_action_just_pressed("zoom_out"):
		#print(find_child("SpringArm3D").spring_length)
		if max_zoom >= find_child("SpringArm3D").spring_length + .25:
			find_child("SpringArm3D").spring_length += .25
	
	if Input.is_action_just_pressed("zoom_in"):
		#print(find_child("SpringArm3D").spring_length)
		if min_zoom <= find_child("SpringArm3D").spring_length - .25:
			find_child("SpringArm3D").spring_length -= .25
	
	#Controler controls
	#if event is InputEventJoypadMotion:
		#if event.axis == 2:
		#	piv.rotate_y(event.axis_value * -mouse_sensitivity * 10)

			#print(event.device)
			#spring_arm.rotate_x(event.axis_value * -mouse_sensitivity * 100)
			#spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)

		#piv.rotate_y(event.relative.x * -mouse_sensitivity)
	
	

		#camera(look_at_override)
	#Mouse controls
	if event is InputEventMouseMotion and not dead and not has_won and not look_at_override:
		spring_arm.rotate_x(event.relative.y * -mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
		piv.rotate_y(event.relative.x * -mouse_sensitivity)
		
		
	if Input.is_action_just_released("swipe"):
		#swipe_stage = 1
		if "sword" in right_hand_item.name:
			if right_hand_item.find_child("swing").playing:
				right_hand_item.find_child("swing").stop()
	
	if Input.is_action_just_pressed("shield"):
		shielding = true
		if "sword" in right_hand_item.name and right_hand_item.find_child("swing").playing:
			right_hand_item.find_child("swing").stop()
			swipping = false
	if Input.is_action_just_released("shield"):
		shielding = false
		if "sword" in right_hand_item.name and Input.is_action_pressed("swipe"):
			right_hand_item.find_child("swing").play()
	
	
	#Menu options
	if message_options:
		if Input.is_action_just_pressed("menu_down"):
			message_option_index -= 1
		if Input.is_action_just_pressed("menu_up"):
			message_option_index += 1
		if message_option_index > len(message_options):
			message_option_index = 1
		if message_option_index < 1:
			message_option_index = len(message_options)
	
	# inventory
	if Input.is_action_just_pressed("slot_1"):
		select_slot(1)
	if Input.is_action_just_pressed("slot_2"):
		select_slot(2)
	if Input.is_action_just_pressed("slot_3"):
		select_slot(3)
	if Input.is_action_just_pressed("slot_4"):
		select_slot(4)
	if Input.is_action_just_pressed("slot_5"):
		select_slot(5)


func get_next_inventory_slot():
	for item_index_r in range(0,len(items)):
		for item_index_c in range(0,len(items[item_index_r])):
			if items[item_index_r][item_index_c] == {} or items[item_index_r][item_index_c] == blank_item:
				return([item_index_r,item_index_c])
	return(false)

func inventory_full():
	if {} in items:
		return false
	else:
		return true
	
	
func walk_sound():
	if walking_on == "dirt":
		var sound_to_use = dirt_sounds.get_children().pick_random()
		#var sound_to_use = dirt_sounds.get_children()[0]
		#$"sounds/walking_dirt/1/sound_light".light_energy
		#$"sounds/walking_dirt/1".
		sound_to_use.play()


func _physics_process(delta):
	if dead:
		return
	walk_sound_every = 1/(velocity.length()/3)
	new_speed = velocity
	if wind != Vector3(0,0,0):
		new_speed += wind
	if knockback != Vector3(0,0,0):
		dazzed = knockback.length() / 100
		new_speed = knockback
		new_speed.y = abs(new_speed.y)
		#print(new_speed)
		#new_speed = knockback
		knockback = Vector3(0,0,0)
	if dazzed > 0:
		dazzed -= delta
		#print(dazzed)
	else:
		dazzed = 0
	# Add the gravity.
	if not is_on_floor() and not swimming:
		new_speed.y -= gravity * delta
	
	if swimming and global_position.y < swim_bob_level - .1:
		new_speed.y = lerp(new_speed.y,float(swim_up_speed * abs(global_position.y)), delta)
		#global_position.y = lerp(global_position.y, swim_bob_level, delta * swim_up_speed)
		
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		new_speed.y += JUMP_VELOCITY
		#swipe_stage = 1
	
	# side jump
	if mid_sidejump:
		if not animation_tree.get("parameters/jump_left/active") and not animation_tree.get("parameters/jump_right/active"):
			mid_sidejump = false
			print("side jump done")
			swipe_stage = 1
		if not sidejump_added:
			sidejump_added = true
			if Input.is_action_pressed("left"):
				var jump_direction = (mesh.transform.basis * sidejump_dir_l).normalized()
				new_speed += jump_direction * sidejump_speed
				print("New speed: " + str(new_speed))
			if Input.is_action_pressed("right"):
				var jump_direction = (mesh.transform.basis * sidejump_dir_r).normalized()
				new_speed += jump_direction * sidejump_speed
	# Backflip
	if mid_backflip:
		if not animation_tree.get("parameters/backflip/active"):
			mid_backflip = false
			swipe_stage = 1
		if not backflip_added:
			backflip_added = true
			var jump_direction = (mesh.transform.basis * backflip_dir).normalized()
			new_speed += jump_direction * backflip_speed
	
	# Jump swipe
	if mid_jump_swipe:
		if not animation_tree.get("parameters/jump_swipe/active"):
			mid_jump_swipe = false
			swipe_stage = 1
		if not jump_swipe_added:
			jump_swipe_added = true
			var jump_direction = (mesh.transform.basis * jump_swipe_dir).normalized() 
			#var direction = (piv.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			new_speed += jump_direction * jump_swipe_speed
		
	if heal_started:
		new_speed = lerp(new_speed,Vector3(0,0,0), delta * 10)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if dazzed == 0 and not heal_started:
		if is_on_floor():
			walk_sounds_timer += delta
			if walk_sounds_timer >= walk_sound_every:
				walk_sound()
				walk_shake = abs((velocity.length()/10) - 1.5)/2
				#print(walk_shake)
				walk_sounds_timer = 0
			#print("wlak sound")
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (piv.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var speed = SPEED
		if shielding and not mid_jump_swipe and is_on_floor():
			speed = SPEED / 2
			var current_blend = animation_tree.get("parameters/shield/blend_amount")
			var new_blend = lerp(current_blend,1.0, delta * 9)
			animation_tree.set("parameters/shield/blend_amount", new_blend)
		elif Input.is_action_pressed("sprint"):
			speed = SPEED * 2
		if direction and not Input.is_action_pressed("swipe"):
			new_speed.x = lerp(new_speed.x, direction.x * speed, delta * 8)
			new_speed.z = lerp(new_speed.z, direction.z * speed, delta * 8)
		else:
			new_speed.x = lerp(new_speed.x, 0.0, delta * 5)
			new_speed.z = lerp(new_speed.z, 0.0, delta * 5)
			#new_speed.x += move_toward(velocity.x, 0, SPEED)
			#new_speed.z += move_toward(velocity.z, 0, SPEED)
		if not shielding or mid_jump_swipe or mid_backflip or mid_sidejump:
			var current_blend = animation_tree.get("parameters/shield/blend_amount")
			var new_blend = lerp(current_blend,0.0, delta * 9)
			animation_tree.set("parameters/shield/blend_amount", new_blend)
	
	velocity = new_speed
	mini_map_cam.global_position.x = global_position.x
	mini_map_cam.global_position.z = global_position.z
	mini_map_cam.global_position.y = global_position.y + abs(mini_map_cam_height * spring_arm.spring_length * 2)
	move_and_slide()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.y < 0:
		swimming = true
	else:
		swimming = false
	if walk_shake > 0:
		var walk_angle = Vector3(20,0,0)
		camera.rotation_degrees = lerp(camera.rotation_degrees, walk_angle, delta * (velocity.length()/5))
		walk_shake -= delta
	elif walk_shake < 0:
		walk_shake = 0
	else:
		camera.rotation_degrees = lerp(camera.rotation_degrees, og_camera_angle, .01)
	
	if swipping:
		swipe_counter -= delta
		if swipe_counter <= 0:
			swipe_counter = 0
			swipping = false
	
	if wind.length() > 0:
		var randome_angle = Vector3(randf_range(-180,180),randf_range(-180,180),randf_range(-180,180))
		camera.rotation_degrees = lerp(camera.rotation_degrees, randome_angle, .003 * wind.length())
		wind = lerp(wind, Vector3(0,0,0),.3)
	
	if shake > 0:
		var randome_angle = Vector3(randf_range(-180,180),randf_range(-180,180),randf_range(-180,180))
		camera.rotation_degrees = lerp(camera.rotation_degrees, randome_angle, .03 * shake)
		shake -= delta
	elif shake < 0:
		shake = 0
	else:
		camera.rotation_degrees = lerp(camera.rotation_degrees, og_camera_angle, .03)
	
	if float(compost) > float(gui_compost.value):
		gui_compost.value = lerp(float(gui_compost.value), float(compost), delta * 10)
	elif float(compost) < float(gui_compost.value):
		gui_compost.value = lerp(float(gui_compost.value), float(compost), delta * 1.3)
		#if abs(float(gui_compost.value) - float(compost)) < .2:
		#	gui_compost.value = lerp(float(gui_compost.value), float(compost), delta * 20)
	
	if cast_cool_down > 0:
		cast_cool_down -= delta
	if compost > max_compost:
		compost = max_compost
	#if life < start_life:
	#	life += delta * life_gen
		#gui.find_child("LIFE").value = (life/start_life) * 100
	if life > start_life:
		life = start_life
	
	if damage_todo != 0:
		if heal_started:
			animation_tree.set("parameters/heal/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
			heal_started = false
			$sounds/heal.playing = false
		if not has_won and shake == 0:
			hurt_sund.play()
			shake = 1
			print("Hurt: " + str(damage_todo))
			life -= damage_todo
		update_life()
		print("life left: " + str(life))
		damage_todo = 0
		if life <= 0 and not dead:
			print("You are dead")
			var RIP = game_over_screen.instantiate()
			get_parent().add_child(RIP)
			dead = true
	
	
	#healing
	if Input.is_action_pressed("heal") and cast_cool_down <= 0:
		if not animation_tree.get("parameters/heal/active") and not heal_started:
			if compost >= 1:
				heal_started = true
				compost -= 1
				animation_tree.set("parameters/heal/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				$sounds/heal.play()
		elif not animation_tree.get("parameters/heal/active") and heal_started:
			print("I'm am healed")
			heal_started = false
			gui_compost.value = compost
			cast_cool_down = cast_cool_down_time
			life += 1
			if life > start_life:
				life = start_life
			update_life()
	elif heal_started:
		heal_started = false
		# Reclame not spent compost
		compost = gui_compost.value
		if animation_tree.get("parameters/heal/active"):
			animation_tree.set("parameters/heal/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
			$sounds/heal.playing = false
	
	if str(inventory["crystals"]) != gui.find_child("crystals").text:
		gui.find_child("crystals").text = str(inventory["crystals"])
	
	if not message_options and message_ui:
		for menu_child in gui.find_child("MESSAGE_BG").get_children():
			print("HI" + str(menu_child))
			if "option" in menu_child.name:
				if menu_child.text != "":
					menu_child.text = ""
	#Shop
	
	#var next_slot = get_next_inventory_slot()
	#if not next_slot:
	#	print("Inventroy Full")
	#else:
	#	print(next_slot)
	
	if look_at_override:
		if message_options:
			var tmp_draw_index = 1
			for message_to_add in message_options:
				var option_name = "option_" + str(tmp_draw_index)
				#gui.find_child("MESSAGE_BG").find_child(option_name).text = message_to_add
				var option_lable = find_child(option_name)
				option_lable.text = message_to_add
				if message_option_index == tmp_draw_index:
					option_lable.set("theme_override_colors/font_color",Color(1,0,0)) 
				else:
					option_lable.set("theme_override_colors/font_color",Color(1,1,1))
				tmp_draw_index += 1
				
			#print(message_options)
		#spring_arm.rotation = Vector3(0,0,0)
		piv.rotation = Vector3(0,PI,0)
		camera_look_target.look_at(look_at_override.global_position)
		#camera_look_target.rotate_object_local(Vector3(0,1,0), -45)
		camera.global_rotation.y = lerp_angle(camera.global_rotation.y, camera_look_target.global_rotation.y, delta)
		#gui.find_child("MESSAGE_LABLE").text = "Press F to buy, E for next item"
		#piv.rotation = lerp(piv.rotation, Vector3(0,-PI,0), delta)
		#print(camera.global_rotation)
	else:
		camera.rotation = lerp(camera.rotation, Vector3(0,0,0),delta*10)
		#print(piv.rotation)
		#print(spring_arm.rotation)
		#print(camera.rotation )
		#spring_arm.global_rotation.x = lerp(spring_arm.global_rotation.x, 0.0, delta)
		#piv.global_rotation.y = lerp(piv.global_rotation.y, 0.0, delta)
		
	
	#NPC messages
	if not message_ui:
		message_box.visible = false
		message_warning.visible = false
		message_bg.visible = false
	if message_ui:
		if not message_box.visible:
			message_warning.visible = true
			#if message_index > -1:
			#	message_box.text = message_ui[message_index]
			#	message_box.visible = true
		else:
			message_warning.visible = false
			#print("message...")
		message_ui = null
	
	#Rotate player
	if not shielding:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-velocity.x, -velocity.z), delta * 18)
		collisionshape.rotation.y = mesh.rotation.y
	
	#set animations
	if shielding:
		animation_tree.set("parameters/shield_timescale/scale", velocity.length())
	
	if not swimming:
		swim_walk_flip = lerp(swim_walk_flip, 0.0, delta)

	else:
		swim_walk_flip = lerp(swim_walk_flip, 1.0, delta)
	animation_tree.set("parameters/stand_run_swim/blend_position", Vector2(velocity.length()/SPEED,swim_walk_flip))
	if velocity.length()/SPEED > 1:
		animation_tree.set("parameters/run_timescale/scale", velocity.length()/SPEED)
		#print(velocity.length()/SPEED)
	else:
		animation_tree.set("parameters/run_timescale/scale", 1)
	
	
	#Controls
	if in_menu:
		return
	var is_active = animation_tree.get(acton_name + "/active")
	if Input.is_action_pressed("swipe") and "sword" in right_hand_item.name:
		if shielding or not is_on_floor():
			if not mid_jump_swipe and not mid_backflip and not mid_sidejump:
				# Jump slash
				if Input.is_action_pressed("forward") or not is_on_floor():
					print("Jump slash")
					#new_speed.y += JUMP_VELOCITY
					animation_tree.set("parameters/jump_swipe/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					mid_jump_swipe = true
					right_hand_item.find_child("swing").seek(0.0)
					right_hand_item.find_child("swing").play()
					jump_swipe_effect.playing = true
					#if is_on_floor():
					jump_swipe_added = false
				# Backflip
				if Input.is_action_pressed("backward") and is_on_floor():
					print("Backflip")
					animation_tree.set("parameters/backflip/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					mid_backflip = true
					backflip_added = false
				
				# sidejump left
				if Input.is_action_pressed("left") and is_on_floor():
					print("Jump left")
					animation_tree.set("parameters/jump_left/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					mid_sidejump = true
					sidejump_added = false
				
				# sidejump right
				if Input.is_action_pressed("right") and is_on_floor():
					print("Jump right")
					animation_tree.set("parameters/jump_right/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					mid_sidejump = true
					sidejump_added = false
				#new_speed.y += JUMP_VELOCITY
				#var jump_direction = (piv.transform.basis * jump_swipe_dir).normalized()
				#new_speed += jump_direction
				#new_speed += jump_swipe_dir
				
		if not shielding:
			if not is_active and is_on_floor() and not mid_jump_swipe and not mid_backflip:
				#animation_tree.set(acton_name + "/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
				acton_name = "parameters/swipe_" + str(swipe_stage)
				animation_tree.set(acton_name + "/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				#animation_tree.set("parameters/swipe_3/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				print("Play " + str(swipe_stage))
				swipe_counter = swipe_speed
				#if not sword.find_child("swing").playing:
				right_hand_item.find_child("swing").play()
				if swipe_stage == 1:
					swipe_1_effect.playing = true
					#print("play1")
				if swipe_stage == 2:
					swipe_2_effect.playing = true
					#print("play2")
				if swipe_stage == 3:
					swipe_3_effect.playing = true
					#print("play3")
				swipe_counter = swipe_speed
				swipping = true
				swipe_stage += 1
				if swipe_stage > total_swipe_stages:
					#print("reset")
					swipe_stage = 1
		else:
			if not is_active:
				swipe_stage = 1
	
	
	if use_controler:
		#Controler 2nd part
		#print(Input.get_joy_axis(0,2))
		piv.rotate_y(Input.get_joy_axis(0,2) * -mouse_sensitivity * delta * 1000)
		spring_arm.rotation.x =  lerp(spring_arm.rotation.x , (PI/2) * -Input.get_joy_axis(0,3), mouse_sensitivity * delta * 1000)

