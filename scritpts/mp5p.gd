extends RigidBody3D

@export var item_id: int = 1
@export var icon_texture: Texture2D

func _ready():
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))

func _on_pickup_zone_body_entered(body):

	if body.name != "PlayerCharacter":
		return

	if not body.has_method("get_slots_node"):
		print("Player does not support inventory")
		return

	var slots_node = body.get_slots_node()
	if slots_node == null or not is_instance_valid(slots_node):
		print("Slots node not found or invalid")
		return

	var slot_name = slots_node.find_first_valid_slot(item_id)
	if slot_name == "":
		print("No valid slot found for item ID: %d" % item_id)
		return

	if not slots_node.has_method("set_slot_item"):
		print("Slots node does not have set_slot_item method")
		return

	slots_node.set_slot_item(slot_name, item_id, icon_texture)
	queue_free()
