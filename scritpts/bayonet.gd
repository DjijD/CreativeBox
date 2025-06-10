extends MeshInstance3D

@export var stab_distance: float = 0.4
@export var stab_speed: float = 18.0
@export var return_speed: float = 18.0

var is_stabbing: bool = false
var returning: bool = false
var start_position: Vector3
var target_position: Vector3

var raycast_created: bool = false
var raycast_scene: PackedScene = preload("res://weapons/0000.tscn")

@onready var weapon_parent: Node3D = get_parent()
@onready var player: Node = get_node("/root/main/PlayerCharacter")
@onready var held_weapon_controller: Node = player.get_node("Camera3D/HeldWeaponController")

func _ready() -> void:
	start_position = weapon_parent.position
	target_position = start_position + Vector3(0, 0, -stab_distance)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shot") and not is_stabbing and not returning:
		if _can_stab():
			_start_stab()

	if is_stabbing:
		weapon_parent.position = weapon_parent.position.lerp(target_position, delta * stab_speed)
		if weapon_parent.position.distance_to(target_position) < 0.01:
			is_stabbing = false
			returning = true
			_spawn_and_remove_raycast()

	elif returning:
		weapon_parent.position = weapon_parent.position.lerp(start_position, delta * return_speed)
		if weapon_parent.position.distance_to(start_position) < 0.01:
			weapon_parent.position = start_position
			returning = false
			raycast_created = false
			print("Готов к следующему удару: RayCast можно создавать снова.")

func _start_stab() -> void:
	is_stabbing = true
	print("Начат удар штыком.")

func _can_stab() -> bool:
	if weapon_parent.position.is_equal_approx(Vector3.ZERO):
		return false

	if player.has_method("is_on_floor") and "is_sprinting" in player and player.has_method("get"):
		if player.is_sprinting > 0.0 and player.is_on_floor() and not player.get("noclip_enabled"):
			print("Удар невозможен: игрок спринтует.")
			return false

	var raycast_node_path = "/root/main/PlayerCharacter/Camera3D/HeldWeaponController/RayCastBayonet"
	var raycast: RayCast3D = get_node_or_null(raycast_node_path)
	if raycast and raycast.is_colliding():
		print("Удар невозможен: RayCastBayonet уже сталкивается с чем-то.")
		return false

	return true

func _spawn_and_remove_raycast() -> void:
	if raycast_created:
		print("RayCast уже создан, новый не создаётся.")
		return

	var temp_raycast: RayCast3D = raycast_scene.instantiate()
	if temp_raycast:
		held_weapon_controller.add_child(temp_raycast)
		temp_raycast.name = "TemporaryRayCast"  # для отладки в дереве
		temp_raycast.position = Vector3.ZERO
		print("RayCast создан: ", temp_raycast)
		raycast_created = true
		await get_tree().process_frame
		if temp_raycast and temp_raycast.is_inside_tree():
			temp_raycast.queue_free()
			print("RayCast удалён: ", temp_raycast)
