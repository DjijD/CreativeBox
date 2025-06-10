extends Label

func _process(delta):
	# Atrod spēlētāju galvenajā mezglā
	var player = get_tree().get_root().get_node("main/PlayerCharacter")
	if player:
		# Mēģina iegūt somu "BagOfPotrons" spēlētāja mezglā
		var bag = player.get_node_or_null("BagOfPotrons")
		if bag:
			# Attēlo somas light_ammunition vērtību
			text = str(bag.light_ammunition)
		else:
			# Ja somas nav, teksts tiek iztukšots
			text = ""
	else:
		# Ja spēlētāja nav, teksts tiek iztukšots
		text = ""
