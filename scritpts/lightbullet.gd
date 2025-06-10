extends RigidBody3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	add_to_group("lightbullet")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.name != "Box":
		queue_free()
