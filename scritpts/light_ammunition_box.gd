extends RigidBody3D

@export var amount: int = 60

func _ready():
	# Savienojam signālu no PickupZone, lai reaģētu uz ieejas notikumu
	$PickupZone.connect("body_entered", Callable(self, "_on_pickup_zone_body_entered"))

func _on_pickup_zone_body_entered(body: Node) -> void:
	# Pārbaudām, vai objektam, kas ieiet zonā, ir nosaukums "PlayerCharacter"
	if body.name != "PlayerCharacter":
		return

	# Mēģinam iegūt "BagOfPotrons" mezglu spēlētājā
	var bag := body.get_node_or_null("BagOfPotrons")
	if bag == null:
		# Ja "BagOfPotrons" nav atrasts, pārtraucam funkciju
		return

	# Palielinām light_ammunition daudzumu somā
	bag.light_ammunition += amount
	
	# Noņemam šo priekšmetu no spēles
	queue_free()
