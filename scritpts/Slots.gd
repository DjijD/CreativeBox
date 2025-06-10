extends Node2D

@onready var slot_names: Array[String] = ["slot1", "slot2", "slot3", "slot4"]
var slots_data: Dictionary = {}
var current_selected_slot: String = ""

var item_textures := {
	1: preload("res://hud/mp5_sprite.png"),
	2: preload("res://hud/vector_sprite.png"),
	3: preload("res://hud/bayonet_sprite.png"),
}

func _ready():
	# Inicializē katru slotu un iestata atļautos priekšmetu ID
	for slot_name in slot_names:
		var slot_node = get_node(slot_name)
		var icon_node = slot_node.get_node("icon")

		var allowed: Array[int] = []
		match slot_name:
			"slot1": allowed = [3]     # Bajonete atļauta tikai pirmajā slotā
			"slot2": allowed = []
			"slot3": allowed = [1, 2]  # MP5 un Vector atļauti šajā slotā
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
	# Atjauno vizuālo stāvokli, lai izceltu izvēlēto slotu
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		slot.selected = (slot_name == selected_name)
		slot.node.modulate = Color(1, 1, 1) if slot.selected else Color(0.5, 0.5, 0.5)
	current_selected_slot = selected_name

func set_slot_item(slot_name: String, item_id: int, item_texture: Texture2D = null) -> void:
	# Iestata priekšmetu slotā, ja tas ir atļauts
	var slot = slots_data.get(slot_name)
	if slot == null:
		return

	if item_id in slot.allowed_items:
		slot.item_id = item_id

		if item_texture != null:
			slot.icon_node.texture = item_texture
		elif item_textures.has(item_id):
			slot.icon_node.texture = item_textures[item_id]
		else:
			slot.icon_node.texture = null
	else:
		# Priekšmets nav atļauts šim slotam
		pass

func get_selected_slot_name() -> String:
	# Atgriež pašreiz izvēlētā slota nosaukumu
	return current_selected_slot

func find_first_valid_slot(item_id: int) -> String:
	# Atrod pirmo tukšo slotu, kurā var ievietot dotā ID priekšmetu
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		if slot.item_id == null and item_id in slot.allowed_items:
			return slot_name
	return ""

func _unhandled_input(event):
	# Apstrādā "drop_item" darbību — izmet aktīvo priekšmetu
	if event.is_action_pressed("drop_item"):
		drop_active_item()

func drop_active_item():
	# Izmet priekšmetu no izvēlētā slota un notīra slotu
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		if slot.selected and slot.item_id != null:
			var player = get_tree().get_current_scene().get_node("PlayerCharacter")
			if player:
				var camera = player.get_node_or_null("Camera3D")
				if camera:
					var dropper = camera.get_node_or_null("ItemDropper")
					if dropper and dropper.has_method("drop_item_from_camera"):
						dropper.drop_item_from_camera()
			# Notīrām slotu
			slot.item_id = null
			slot.icon_node.texture = null
			return

func get_active_slot() -> Dictionary:
	# Atgriež pašreiz izvēlēto slotu kā vārdnīcu, ja nav — tukšu vārdnīcu
	for slot_name in slot_names:
		var slot = slots_data[slot_name]
		if slot.selected:
			return slot
	return {}
