extends Node3D

# Tavs ieroču dati (atstāju kā ir)
var weapon_scenes: Dictionary = {
	1: {
		"scene": preload("res://weapons/mp5.tscn"),
		"default_position": Vector3(0.339, -0.328, -0.573),
		"default_rotation": Vector3(-0.4, 96.8, 5.9),
		"draw_position": Vector3(0.339, -0.106, -0.322),
		"draw_rotation": Vector3(-6.5, 92, 75.7),
		"sprint_position": Vector3(0.339, -0.43, -0.618),
		"sprint_rotation": Vector3(-0.2, 176.2, -37.8),
		"raycast_target_position": Vector3(0.339, -0.106, -0.322),
		"raycast_target_rotation": Vector3(-6.5, 92, 75.7),
		"aim_position": Vector3(0.0, -0.223, -0.435),
		"aim_rotation": Vector3(0.0, 91.7, 0.0),
		"current_ammo": 30,
		"max_ammo": 30,
		"ammo_type": "light_ammunition"
	},
	2: {
		"scene": preload("res://weapons/vector.tscn"),
		"default_position": Vector3(0.312, -0.332, -0.797),
		"default_rotation": Vector3(0, -83.2, -5.3),
		"draw_position": Vector3(0.312, 0.183, -0.548),
		"draw_rotation": Vector3(6.7, -88.8, -80),
		"sprint_position": Vector3(-0.174, -0.595, -0.485),
		"sprint_rotation": Vector3(6.7, -10.2, 24.9),
		"raycast_target_position": Vector3(0.312, 0.183, -0.548),
		"raycast_target_rotation": Vector3(6.7, -88.8, -80),
		"aim_position": Vector3(0.0, -0.324, -0.648),
		"aim_rotation": Vector3(0.0, -88.8, 0.0),
		"current_ammo": 17,
		"max_ammo": 17,
		"ammo_type": "light_ammunition"
	},
	3: {
		"scene": preload("res://weapons/bayonet.tscn"),
		"default_position": Vector3(0.445, -0.306, -0.792),
		"default_rotation": Vector3(0, 90, 7.7),
		"draw_position": Vector3(0.445, -0.19, -0.792),
		"draw_rotation": Vector3(0, 90, 42.1),
		"sprint_position": Vector3(0.445, -0.5, -0.792),
		"sprint_rotation": Vector3(-5, 120, 20),
		"raycast_target_position": Vector3(0.445, -0.097, -0.402),
		"raycast_target_rotation": Vector3(0, 90, 78.9)
	}
}

var current_weapon: Node3D = null
var current_weapon_id: int = -1
var is_aiming: bool = false

@onready var slots_node: Node = get_node("/root/main/PlayerCharacter/HUD/slots")
@onready var player: Node = get_node("/root/main/PlayerCharacter")

var tween: Tween = null

# Jauna mainīgā — reload stāvoklis
var is_reloading: bool = false

func _input(event: InputEvent) -> void:
	# Mērķēšanas pārslēgšana, ja netiek skrīnots un netiek pārlādēts
	if event.is_action_pressed("aim"):
		if not is_player_sprinting() and not is_reloading:
			is_aiming = !is_aiming
	
	# Pārlādēšanas sākums, ja pašreizējais ierocis ir MP5 vai Vector
	if event.is_action_pressed("reload"):
		if not is_reloading and (current_weapon_id == 1 or current_weapon_id == 2):
			start_reload()

func _process(_delta: float) -> void:
	if is_reloading:
		# Reload laikā neveicam citus stāvokļu pārslēgumus
		return
	
	if slots_node == null or player == null:
		return

	var active_slot: Dictionary = slots_node.call("get_active_slot")
	if not active_slot.has("item_id") or typeof(active_slot["item_id"]) != TYPE_INT:
		remove_weapon()
		return

	var item_id: int = active_slot["item_id"]
	if item_id != current_weapon_id:
		if weapon_scenes.has(item_id):
			show_weapon(item_id)
		else:
			remove_weapon()
		return

	var is_sprinting = is_player_sprinting()

	if is_sprinting:
		is_aiming = false  # noņem mērķēšanu sprinta laikā

	# RayCast pārbaude atkarībā no ierocim
	var raycast_path := ""
	match current_weapon_id:
		1: raycast_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastMP5"
		2: raycast_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastVector"
		3: raycast_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastBayonet"

	if raycast_path != "":
		var raycast: RayCast3D = get_node_or_null(raycast_path)
		if raycast and raycast.is_colliding():
			is_aiming = false
			# _print_debug("Raycast sasniedza objektu")
			var data = weapon_scenes[current_weapon_id]
			animate_weapon(data["raycast_target_position"], data["raycast_target_rotation"])
			return

	var data = weapon_scenes[current_weapon_id]

	if is_sprinting:
		# _print_debug("Sprints: sprinta poza")
		animate_weapon(data["sprint_position"], data["sprint_rotation"])
	elif is_aiming and data.has("aim_position"):
		# _print_debug("Mērķēšana")
		animate_weapon(data["aim_position"], data["aim_rotation"])
	else:
		# _print_debug("Parastais stāvoklis")
		animate_weapon(data["default_position"], data["default_rotation"])

func start_reload() -> void:
	is_reloading = true
	var data = weapon_scenes[current_weapon_id]
	
	# Atspējo mērķēšanu, sprintu utt.
	is_aiming = false

	# Animē ieroci sprinta pozā
	animate_weapon(data["sprint_position"], data["sprint_rotation"], 0.25)

	# Gaida 1 sekundi pirms reload pabeigšanas
	await get_tree().create_timer(1.0).timeout

	# Reload pabeigts
	is_reloading = false

func is_player_sprinting() -> bool:
	if "is_sprinting" in player and player.has_method("is_on_floor"):
		return player.is_sprinting > 0.0 and player.is_on_floor() and not player.get("noclip_enabled")
	return false

func show_weapon(item_id: int) -> void:
	remove_weapon()

	if not weapon_scenes.has(item_id):
		return

	var data: Dictionary = weapon_scenes[item_id]
	current_weapon = data["scene"].instantiate() as Node3D
	add_child(current_weapon)

	current_weapon.position = data["draw_position"]
	current_weapon.rotation_degrees = data["draw_rotation"]
	animate_weapon(data["default_position"], data["default_rotation"], 0.25)

	current_weapon_id = item_id
	is_aiming = false

func animate_weapon(target_pos: Vector3, target_rot: Vector3, duration: float = 0.2) -> void:
	if not current_weapon:
		return

	if current_weapon.position == target_pos and current_weapon.rotation_degrees == target_rot:
		return

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(current_weapon, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(current_weapon, "rotation_degrees", target_rot, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func remove_weapon() -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = null

	if current_weapon and is_instance_valid(current_weapon):
		current_weapon.queue_free()
	current_weapon = null
	current_weapon_id = -1
	is_aiming = false

	# Tukša funkcija — debug izvad
