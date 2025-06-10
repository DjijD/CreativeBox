extends Node3D

@export var amount: int = 15  # Munīcijas daudzums, ko pievienot

func _ready():
	# Pieslēdz notikumu, kad kāds ķermenis ieiet PickupZone
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))

func _on_pickup_zone_body_entered(body: Node) -> void:
	# Pārbauda, vai ķermenis ir spēlētājs
	if body.name != "PlayerCharacter":
		return

	# Mēģina atrast BagOfPotrons somu spēlētāja mezglā
	var bag := body.get_node_or_null("BagOfPotrons")
	if bag == null:
		# Ja soma nav atrasta, pārtrauc
		return

	# Pievieno smago munīciju somai
	bag.heavy_ammunition += amount
	# Noņem šo objektu no pasaules (paņemts)
	queue_free()
