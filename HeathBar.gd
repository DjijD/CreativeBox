extends TextureProgressBar

@onready var player = get_node("/root/main/PlayerCharacter")

func _process(_delta):
	if player:
		value = player.health
