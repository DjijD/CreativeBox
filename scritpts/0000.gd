extends RayCast3D

var damage = 15  # Bojājuma daudzums, ko nodarīt ienaidniekam

func _ready():
	enabled = true  # Ieslēdzam RayCast, lai tas sāktu darboties

	# Cast_to var pielāgot, ja vajadzīgs — parasti vērsts uz priekšu

func _process(delta):
	# Ja RayCast saskaras ar objektu
	if is_colliding():
		var collider = get_collider()
		# Pārbaudām, vai tas ir ienaidnieks un vai var saņemt bojājumus
		if collider and collider.is_in_group("enemies"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)  # Nododam bojājumus ienaidniekam
				queue_free()  # Iznīcinām RayCast, lai tas nenodara atkārtotus bojājumus
