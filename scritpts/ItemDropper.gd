extends Node

# Предметы, которые можно выбросить
var droppable_items: Dictionary = {
	1: {
		"scene": preload("res://items/mp5p.tscn"),
		"name": "MP5",
		"throw_force": 6.0
	},
	2: {
		"scene": preload("res://items/vectorp.tscn"),
		"name": "Vector",
		"throw_force": 6.0
	},
	3: {
		"scene": preload("res://items/bayonetp.tscn"),
		"name": "Bayonet",
		"throw_force": 4.0
	}
}

@onready var camera: Camera3D = get_parent()
@onready var slots: Node = get_node("/root/main/PlayerCharacter/HUD/slots")

func drop_item_from_camera() -> void:
	var slot_name: String = slots.get_selected_slot_name()
	var slot_data: Dictionary = slots.slots_data.get(slot_name)

	if slot_data == null or slot_data.item_id == null:
		print("❌ Слот пуст или не найден.")
		return

	var item_id: int = slot_data.item_id
	if not droppable_items.has(item_id):
		print("❌ Этот предмет нельзя выбросить: ID = %d" % item_id)
		return

	var item_info: Dictionary = droppable_items[item_id]
	var scene: PackedScene = item_info["scene"]
	var throw_force: float = item_info.get("throw_force", 2.0)

	# Убираем предмет из слота
	slot_data.item_id = null
	if slot_data.has("icon_node") and slot_data.icon_node:
		slot_data.icon_node.texture = null

	# Создаем экземпляр предмета
	var item_instance: Node3D = scene.instantiate()

	if item_instance is RigidBody3D:
		get_tree().current_scene.add_child(item_instance)

		# Спавним предмет перед камерой
		var spawn_pos: Vector3 = camera.global_transform.origin + (-camera.global_transform.basis.z) * 1.5
		item_instance.global_transform.origin = spawn_pos

		# Импульс вперед от камеры
		var impulse_dir: Vector3 = (-camera.global_transform.basis.z).normalized()
		var impulse: Vector3 = impulse_dir * throw_force
		item_instance.apply_central_impulse(impulse)

		# Защита от мгновенного подбора
		if item_instance.has_method("disable_pickup_temporarily"):
			item_instance.call_deferred("disable_pickup_temporarily", 1.5)
	else:
		print("❌ Предмет должен быть типа RigidBody3D.")
