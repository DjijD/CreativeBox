extends Node3D

@onready var pl = $PlayerCharacter  # Atsauce uz spēlētāja raksturu

func _physics_process(delta):
	# Izsaucam metodi "update_target_location" visiem grupas "enemies" objektiem,
	# nododot spēlētāja atrašanās vietu kā mērķa pozīciju
	get_tree().call_group("enemies", "update_target_location", pl.global_transform.origin)
