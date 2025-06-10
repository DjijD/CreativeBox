extends RigidBody3D

@export var item_id: int = 3
@export var icon_texture: Texture2D

var can_be_picked_up := false

func _ready():
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))
	disable_pickup_temporarily(0.6) # īslaicīgi bloķē pacelšanu pēc parādīšanās

func disable_pickup_temporarily(duration: float):
	can_be_picked_up = false
	$PickupZone.set_deferred("monitoring", false)
	await get_tree().create_timer(duration).timeout
	can_be_picked_up = true
	$PickupZone.set_deferred("monitoring", true)

func _on_pickup_zone_body_entered(body):
	if not can_be_picked_up:
		return

	if body.name != "PlayerCharacter":
		return

	if not body.has_method("get_slots_node"):
		print("⚠️ Spēlētājam nav inventāra sistēmas.")
		return

	var slots_node = body.get_slots_node()
	if slots_node == null or not is_instance_valid(slots_node):
		print("⚠️ Inventāra mezgls nav atrasts vai ir nederīgs.")
		return

	var slot_name = slots_node.find_first_valid_slot(item_id)
	if slot_name == "":
		print("⚠️ Nav derīga slota priekš priekšmeta ID: %d" % item_id)
		return

	if not slots_node.has_method("set_slot_item"):
		print("⚠️ Inventārs nesatur metodi set_slot_item.")
		return

	slots_node.set_slot_item(slot_name, item_id, icon_texture)
	queue_free() # izdzēš priekšmetu pēc pacelšanas
