extends Node3D

@export var fire_rate: float = 0.08
@export var recoil_amount: float = 0.1
@export var camera_recoil_amount: float = -2.0  # градусы поворота камеры вверх при выстреле
@export var reload_time: float = 1.0  # время перезарядки в секундах
@export var bullet_speed: float = 65.0  # скорость пули (сделал 10 для наглядности)

var last_shot_timestamp: float = -10000.0
var is_reloading: bool = false
var bullet_spawner_ready: bool = false

var default_pos: Vector3 = Vector3.ZERO
var aim_pos: Vector3 = Vector3.ZERO
var sprint_pos: Vector3 = Vector3.ZERO
var raycast_target_pos: Vector3 = Vector3.ZERO

@onready var weapon_parent: Node3D = get_parent()
@onready var player: Node = get_node("/root/main/PlayerCharacter")
@onready var ammo_data := player.get_node_or_null("BagOfPotrons")
@onready var camera: Camera3D = player.get_node("Camera3D")

@onready var bullet_scene: PackedScene = preload("res://weapons/lightbullet.tscn")

var bullet_spawner: Node3D = null

func _ready() -> void:
	# Pārbaudām, vai ir metode, kas dod ieroča pozīciju datus
	if weapon_parent.has_method("get_weapon_position_data"):
		var pos_data = weapon_parent.call("get_weapon_position_data")
		default_pos = pos_data.get("default_position", weapon_parent.position)
		aim_pos = pos_data.get("aim_position", weapon_parent.position)
		sprint_pos = pos_data.get("sprint_position", Vector3.ZERO)
		raycast_target_pos = pos_data.get("raycast_target_position", Vector3.ZERO)
	else:
		# Ja metode nav, izmantojam ieroča pašreizējo pozīciju
		default_pos = weapon_parent.position
		aim_pos = weapon_parent.position
	
	_find_bullet_spawner_async()

func _find_bullet_spawner_async() -> void:
	# Meklējam BulletSpawner mezglu ieroča hierarhijā
	bullet_spawner = weapon_parent.get_node_or_null("mp5/MP5_10_0/BulletSpawner")
	if bullet_spawner == null or not bullet_spawner.is_inside_tree():
		bullet_spawner_ready = false
		await get_tree().process_frame
		await _find_bullet_spawner_async()
	else:
		bullet_spawner_ready = true

func _process(delta: float) -> void:
	# Pārbaudām, vai nospiesta pārlādēšanas poga un ieročs netiek pārlādēts
	if Input.is_action_just_pressed("reload") and not is_reloading:
		_start_reload()

	# Ja tiek turēta šaušanas poga, mēģinām šaut
	if Input.is_action_pressed("shot"):
		_try_fire()

	# Izvēlamies mērķa pozīciju un lēni pārvietojam ieroča pozīciju uz to
	var desired_pos = _select_target_position()
	if weapon_parent.position.distance_to(desired_pos) > 0.001:
		weapon_parent.position = weapon_parent.position.lerp(desired_pos, 0.2)

func _try_fire() -> void:
	# Neļauj šaut, ja notiek pārlāde vai BulletSpawner vēl nav gatavs
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

	if ammo_data.mp5_current_ammo <= 0:
		return

	_execute_fire()
	ammo_data.mp5_current_ammo -= 1
	last_shot_timestamp = now
	_apply_recoil()
	_apply_camera_recoil()

func _start_reload() -> void:
	is_reloading = true
	_reload_async()

func _reload_async() -> void:
	var timer = get_tree().create_timer(reload_time)
	await timer.timeout

	var needed = ammo_data.mp5_max_ammo - ammo_data.mp5_current_ammo
	if needed > 0 and ammo_data.light_ammunition > 0:
		var to_reload = min(needed, ammo_data.light_ammunition)
		ammo_data.mp5_current_ammo += to_reload
		ammo_data.light_ammunition -= to_reload

	is_reloading = false

func _can_fire() -> bool:
	# Neļauj šaut, ja ieroča pozīcija atbilst sprintam vai mērķa pozīcijai
	if weapon_parent.position.is_equal_approx(sprint_pos) or weapon_parent.position.is_equal_approx(raycast_target_pos):
		return false

	# Neļauj šaut, ja spēlētājs skrien un atrodas uz zemes bez noclip režīma
	if player.has_method("is_on_floor") and "is_sprinting" in player and player.has_method("get"):
		if player.is_sprinting > 0.0 and player.is_on_floor() and not player.get("noclip_enabled"):
			return false

	# Pārbaudām, vai raycast saduras ar kādu objektu
	var raycast_node_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastMP5"
	var raycast: RayCast3D = get_node_or_null(raycast_node_path)
	if raycast:
		if raycast.is_colliding():
			return false

	return true

func _select_target_position() -> Vector3:
	# Izvēlas tuvāko no default vai aim pozīcijām
	var dist_to_default = weapon_parent.position.distance_to(default_pos)
	var dist_to_aim = weapon_parent.position.distance_to(aim_pos)
	return default_pos if dist_to_default < dist_to_aim else aim_pos

func _apply_recoil() -> void:
	# Pielieto atsitienu ieročam
	weapon_parent.position += Vector3(0, 0, recoil_amount)

func _apply_camera_recoil() -> void:
	# Pielieto atsitienu kamerai
	var rot = camera.rotation_degrees
	rot.x = clamp(rot.x - camera_recoil_amount, -90, 90)
	camera.rotation_degrees = rot

func _execute_fire() -> void:
	# Pārbaudām, vai BulletSpawner ir derīgs
	if bullet_spawner == null or not bullet_spawner.is_inside_tree():
		return

	# Izveidojam jaunu lodes instanci
	var bullet_instance = bullet_scene.instantiate()
	if bullet_instance == null:
		return

	# Pievienojam lodi pašreizējai ainas saknei
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	current_scene.add_child(bullet_instance)

	# Uzstādām lodes transformāciju un pozīciju atbilstoši BulletSpawner
	bullet_instance.global_transform = bullet_spawner.global_transform

	# Noteicam lodes lidojuma virzienu (pa x ass)
	var direction = bullet_spawner.global_transform.basis.x.normalized()

	# Uzstādam lodes ātrumu
	if bullet_instance.has_method("set_linear_velocity"):
		bullet_instance.set_linear_velocity(direction * bullet_speed)
	elif bullet_instance.has_variable("linear_velocity"):
		bullet_instance.linear_velocity = direction * bullet_speed
