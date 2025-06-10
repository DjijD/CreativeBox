extends RigidBody3D

@export var hp: int = 100  # Lodziņa dzīvības punkti

func _ready() -> void:
	contact_monitor = true  # Iespējo kontakta monitorēšanu
	max_contacts_reported = 10  # Maksimālais kontaktu skaits, ko ziņot
	connect("body_entered", Callable(self, "_on_body_entered"))  # Pieslēdz notikumu, kad kāds ķermenis ietriecas

func _on_body_entered(body: Node) -> void:
	# Ja ietriecas ķermenis pieder "lightbullet" grupai
	if body.is_in_group("lightbullet"):
		hp -= 40  # Samazina dzīvības punktus par 40
		if hp <= 0:
			# Ja dzīvības punkti beigušies, dzēš šo objektu
			queue_free()
