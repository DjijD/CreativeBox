extends RigidBody3D

@export var item_id: int = 1
@export var icon_texture: Texture2D

var can_be_picked_up := false

func _ready():
	# Pieslēdzam signālu, kad ķermenis ieiet PickupZone zonā
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))
	# Laicīgi bloķējam priekšmetu paņemšanu uz 0.6 sekundēm pēc parādīšanās
	disable_pickup_temporarily(0.6)

func disable_pickup_temporarily(duration: float):
	can_be_picked_up = false
	$PickupZone.set_deferred("monitoring", false)  # Izslēdzam zonas monitoringu, lai neļautu pacelt
	await get_tree().create_timer(duration).timeout
	can_be_picked_up = true
	$PickupZone.set_deferred("monitoring", true)  # Ieslēdzam zonas monitoringu atpakaļ

func _on_pickup_zone_body_entered(body):
	# Ja priekšmets vēl nav pieejams pacelšanai, iziet no funkcijas
	if not can_be_picked_up:
		return

	# Pacel tikai tad, ja ķermenis ir spēlētājs
	if body.name != "PlayerCharacter":
		return

	# Pārbauda, vai spēlētājam ir inventāra mezgls
	if not body.has_method("get_slots_node"):
		return

	var slots_node = body.get_slots_node()
	# Pārbauda, vai mezgls ir derīgs un eksistē
	if slots_node == null or not is_instance_valid(slots_node):
		return

	# Atrod piemērotu slotu priekš šī priekšmeta ID
	var slot_name = slots_node.find_first_valid_slot(item_id)
	if slot_name == "":
		return

	# Pārbauda, vai slots_node atbalsta priekšmeta iestatīšanas metodi
	if not slots_node.has_method("set_slot_item"):
		return

	# Uzstāda priekšmetu slotā ar ID un ikonu
	slots_node.set_slot_item(slot_name, item_id, icon_texture)
	# Noņem priekšmetu no spēles pasaules pēc paņemšanas
	queue_free()
