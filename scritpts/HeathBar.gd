extends TextureProgressBar

# Saistīšanās ar spēlētāja mezglu
@onready var player = get_node("/root/main/PlayerCharacter")

func _process(_delta):
	# Ja spēlētājs ir pieejams, atjauno veselības joslas vērtību
	if player:
		value = player.health
