extends Node2D

@onready var slot_names: Array[String] = ["slot1", "slot2", "slot3", "slot4"]
var slots_data: Dictionary = {}
var current_selected_slot: String = ""

var item_textures := {
	1: preload("res://hud/mp5_sprite.png"),
}

func _ready():
	for slot_name in slot_names:
		var slot_node = get_node(slot_name)
		var icon_node = slot_node.get_node("icon")

		var allowed: Array[int] = []
		match slot_name:
			"slot1": allowed = []
			"slot2": allowed = []
			"slot3": allowed = [1]
			"slot4": allowed = []

		slots_data[slot_name] = {
			"node": slot_node,
			"icon_node": icon_node,
			"item_id": null,
			"selected": false,
			"allowed_items": allowed
		}

	update_selection(slot_names[0])

func update_selection(selected_name: String) -> void:
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		slot.selected = (slot_name == selected_name)
		slot.node.modulate = Color(1, 1, 1) if slot.selected else Color(0.5, 0.5, 0.5)
	current_selected_slot = selected_name

func set_slot_item(slot_name: String, item_id: int, item_texture: Texture2D = null) -> void:
	var slot = slots_data.get(slot_name)
	if slot == null:
		print("Slots nav atrasts: ", slot_name)
		return

	if item_id in slot.allowed_items:
		slot.item_id = item_id

		if item_texture != null:
			slot.icon_node.texture = item_texture
		elif item_textures.has(item_id):
			slot.icon_node.texture = item_textures[item_id]
		else:
			slot.icon_node.texture = null
			print("Vienumam ar ID nav tekstūras ", item_id)
	else:
		print("Nevar ievietot preci ar ID ", item_id, " slotā ", slot_name)

func get_selected_slot_name() -> String:
	return current_selected_slot

func find_first_valid_slot(item_id: int) -> String:
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		if slot.item_id == null and item_id in slot.allowed_items:
			return slot_name
	return ""
