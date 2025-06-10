extends RigidBody3D

@export var item_id: int = 2
@export var icon_texture: Texture2D

var can_be_picked_up := false

func _ready():
	# Savienojam signālu, kas reaģē, kad kāds ieiet priekšmeta paņemšanas zonā
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))
	# Aizliegums tūlītēji paņemt priekšmetu pēc radīšanas
	disable_pickup_temporarily(0.6)

func disable_pickup_temporarily(duration: float):
	# Atspējo priekšmeta paņemšanu uz noteiktu laiku
	can_be_picked_up = false
	$PickupZone.set_deferred("monitoring", false)
	await get_tree().create_timer(duration).timeout
	can_be_picked_up = true
	$PickupZone.set_deferred("monitoring", true)

func _on_pickup_zone_body_entered(body):
	# Ja paņemšana nav iespējama, tad neturam neko
	if not can_be_picked_up:
		return

	# Pārbaudam, vai ķermenis ir spēlētājs
	if body.name != "PlayerCharacter":
		return

	# Pārbaudam, vai spēlētājam ir inventāra atbalsts
	if not body.has_method("get_slots_node"):
		return

	var slots_node = body.get_slots_node()
	# Pārbaudam, vai inventāra mezgls eksistē un ir derīgs
	if slots_node == null or not is_instance_valid(slots_node):
		return

	# Atrodam pirmo derīgo slotu priekš šī priekšmeta ID
	var slot_name = slots_node.find_first_valid_slot(item_id)
	if slot_name == "":
		return

	# Pārbaudam, vai inventāra mezglam ir nepieciešamā metode priekš iestatīšanas
	if not slots_node.has_method("set_slot_item"):
		return

	# Iestatam priekšmetu slotā un noņemam objektu no pasaules
	slots_node.set_slot_item(slot_name, item_id, icon_texture)
	queue_free()
