extends Node3D

@export var fire_rate: float = 0.04                        # Raidstreliena ātrums (sekundēs)
@export var recoil_amount: float = 0.05                    # Atgrūšanās spēks ieročam
@export var camera_recoil_amount: float = -1.8             # Kameras pagrieziens grādos pēc šāviena (uz augšu)
@export var reload_time: float = 1.0                        # Pārlādēšanas laiks sekundēs
@export var bullet_speed: float = 60.0                      # Lodes ātrums

var last_shot_timestamp: float = -10000.0                   # Laiks pēdējam šāvienam
var is_reloading: bool = false                               # Vai pašlaik notiek pārlāde
var bullet_spawner_ready: bool = false                       # Vai BulletSpawner ir gatavs

var default_pos: Vector3 = Vector3.ZERO                      # Ieroča noklusētā pozīcija
var aim_pos: Vector3 = Vector3.ZERO                          # Mērķēšanas pozīcija
var sprint_pos: Vector3 = Vector3.ZERO                       # Skriešanas pozīcija
var raycast_target_pos: Vector3 = Vector3.ZERO               # Raycast mērķa pozīcija

@onready var weapon_parent: Node3D = get_parent()           # Ieroča vecāks
@onready var player: Node = get_node("/root/main/PlayerCharacter")  # Spēlētājs
@onready var ammo_data := player.get_node_or_null("BagOfPotrons")  # Munīcijas dati
@onready var camera: Camera3D = player.get_node("Camera3D")        # Kamera

@onready var bullet_scene: PackedScene = preload("res://weapons/lightbullet.tscn")  # Lodes scena

var bullet_spawner: Node3D = null                            # Punkts, no kura rodas lodes

func _ready() -> void:
	# Mēģina iegūt ieroča pozīciju datus, ja pieejami
	if weapon_parent.has_method("get_weapon_position_data"):
		var pos_data = weapon_parent.call("get_weapon_position_data")
		default_pos = pos_data.get("default_position", weapon_parent.position)
		aim_pos = pos_data.get("aim_position", weapon_parent.position)
		sprint_pos = pos_data.get("sprint_position", Vector3.ZERO)
		raycast_target_pos = pos_data.get("raycast_target_position", Vector3.ZERO)
	else:
		default_pos = weapon_parent.position
		aim_pos = weapon_parent.position
	
	_find_bullet_spawner_async()

# Asinhroni meklē BulletSpawner mezglu un gaida, ja tas vēl nav gatavs
func _find_bullet_spawner_async() -> void:
	bullet_spawner = weapon_parent.get_node_or_null("vector/BulletSpawner")
	if bullet_spawner == null or not bullet_spawner.is_inside_tree():
		bullet_spawner_ready = false
		await get_tree().process_frame
		await _find_bullet_spawner_async()
	else:
		bullet_spawner_ready = true

func _process(delta: float) -> void:
	# Pārbauda, vai nospiesta pārlādes poga
	if Input.is_action_just_pressed("reload") and not is_reloading:
		_start_reload()

	# Ja tiek turēta šāviena poga — mēģina šaut
	if Input.is_action_pressed("shot"):
		_try_fire()

	# Ieroča pozīcijas interpolācija starp pašreizējo un mērķa pozīciju
	var desired_pos = _select_target_position()
	if weapon_parent.position.distance_to(desired_pos) > 0.001:
		weapon_parent.position = weapon_parent.position.lerp(desired_pos, 0.2)

func _try_fire() -> void:
	if is_reloading:
		return

	if not bullet_spawner_ready:
		return

	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shot_timestamp < fire_rate:
		return

	if not _can_fire():
		return

	if ammo_data == null:
		return

	if ammo_data.vector_current_ammo <= 0:
		return

	_execute_fire()
	ammo_data.vector_current_ammo -= 1
	last_shot_timestamp = now
	_apply_recoil()
	_apply_camera_recoil()

func _start_reload() -> void:
	is_reloading = true
	_reload_async()

func _reload_async() -> void:
	var timer = get_tree().create_timer(reload_time)
	await timer.timeout

	var needed = ammo_data.vector_max_ammo - ammo_data.vector_current_ammo
	if needed > 0 and ammo_data.light_ammunition > 0:
		var to_reload = min(needed, ammo_data.light_ammunition)
		ammo_data.vector_current_ammo += to_reload
		ammo_data.light_ammunition -= to_reload

	is_reloading = false

func _can_fire() -> bool:
	# Neļauj šaut, ja ierocis atrodas skrējiena vai raycast pozīcijā
	if weapon_parent.position.is_equal_approx(sprint_pos) or weapon_parent.position.is_equal_approx(raycast_target_pos):
		return false

	# Neļauj šaut, ja spēlētājs skrien uz zemes bez noclip
	if player.has_method("is_on_floor") and "is_sprinting" in player and player.has_method("get"):
		if player.is_sprinting > 0.0 and player.is_on_floor() and not player.get("noclip_enabled"):
			return false

	var raycast_node_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastVector"
	var raycast: RayCast3D = get_node_or_null(raycast_node_path)
	if raycast:
		if raycast.is_colliding():
			return false

	return true

func _select_target_position() -> Vector3:
	var dist_to_default = weapon_parent.position.distance_to(default_pos)
	var dist_to_aim = weapon_parent.position.distance_to(aim_pos)
	return default_pos if dist_to_default < dist_to_aim else aim_pos

func _apply_recoil() -> void:
	# Pielieto atgrūšanos ieročam
	weapon_parent.position += Vector3(0, 0, recoil_amount)

func _apply_camera_recoil() -> void:
	# Pielieto kamerai atgrūšanos (pagriež uz augšu)
	var rot = camera.rotation_degrees
	rot.x = clamp(rot.x - camera_recoil_amount, -90, 90)
	camera.rotation_degrees = rot

func _execute_fire() -> void:
	# Pārbauda, vai BulletSpawner ir gatavs
	if bullet_spawner == null or not bullet_spawner.is_inside_tree():
		return

	var bullet_instance = bullet_scene.instantiate()
	if bullet_instance == null:
		return

	# Pievieno lodi pašreizējai ainai
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	current_scene.add_child(bullet_instance)

	# Uzstāda lodes pozīciju un virzienu
	bullet_instance.global_transform = bullet_spawner.global_transform

	# Virziens ir pretējā virzienā no BulletSpawner lokālā X ass
	var direction = -bullet_spawner.global_transform.basis.x.normalized()

	if bullet_instance.has_method("set_linear_velocity"):
		bullet_instance.set_linear_velocity(direction * bullet_speed)
	elif bullet_instance.has_variable("linear_velocity"):
		bullet_instance.linear_velocity = direction * bullet_speed
