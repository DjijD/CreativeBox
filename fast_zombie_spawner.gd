extends Node3D

@export var zombie_scene: PackedScene
@export var spawn_interval: float = 15.0

var _timer := 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_zombie()

func _spawn_zombie() -> void:
	if zombie_scene:
		var zombie_instance = zombie_scene.instantiate()
		get_parent().add_child(zombie_instance)
		zombie_instance.global_transform.origin = global_transform.origin
