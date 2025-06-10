extends Label

# Saistīšanās ar spēlētāja mezgliem
@onready var player = get_node("/root/main/PlayerCharacter")
@onready var bag = player.get_node_or_null("BagOfPotrons")  # Soma ar patronām
@onready var held_weapon_controller = get_node_or_null("/root/main/PlayerCharacter/Camera3D/HeldWeaponController")  # Ierocis, ko spēlētājs tur rokā

func _process(_delta: float) -> void:
	# Ja soma vai ieroča kontrolleris nav pieejams, rāda 0 / 0
	if bag == null or held_weapon_controller == null:
		text = "0 / 0"
		return

	var current_ammo = 0
	var max_ammo = 0
	
	var current_weapon_id = -1
	# Iegūst pašreizējo ieroča ID, ja tāds ir
	if held_weapon_controller.has_method("get_current_weapon_id"):
		current_weapon_id = held_weapon_controller.call("get_current_weapon_id")
	elif "current_weapon_id" in held_weapon_controller:
		current_weapon_id = held_weapon_controller.current_weapon_id

	# Pamatojoties uz ieroča ID, iestata patronu skaitu
	match current_weapon_id:
		1:  # mp5
			current_ammo = bag.mp5_current_ammo
			max_ammo = bag.mp5_max_ammo
		2:  # vector
			current_ammo = bag.vector_current_ammo
			max_ammo = bag.vector_max_ammo
		3:  # bayonet (bez patronām)
			current_ammo = 0
			max_ammo = 0
		_:
			current_ammo = 0
			max_ammo = 0

	# Atjauno tekstu uz ekrāna ar patronu skaitu
	text = "%d / %d" % [current_ammo, max_ammo]
