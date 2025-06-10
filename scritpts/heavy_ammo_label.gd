extends Label

func _process(delta):
	# Atrodam spēlētāja mezglu
	var player = get_tree().get_root().get_node("main/PlayerCharacter")
	if player:
		# Mēģinām atrast BagOfPotrons mezglu spēlētāja hierarhijā
		var bag = player.get_node_or_null("BagOfPotrons")
		if bag:
			# Attēlo smagās munīcijas daudzumu somā
			text = str(bag.heavy_ammunition)
		else:
			# Ja soma nav pieejama
			text = "No BagOfPotrons"
	else:
		# Ja spēlētājs nav atrasts
		text = "No PlayerCharacter"
