extends Area3D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("lightbullet"):
		return
	_forward_hit()

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("lightbullet"):
		return
	_forward_hit()

func _forward_hit():
	var current = self
	while current:
		if current.has_method("_process_hit"):
			current._process_hit(self)
			return
		current = current.get_parent()
	print("HitZone.gd: не удалось найти родителя с _process_hit()")
