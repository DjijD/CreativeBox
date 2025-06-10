extends CharacterBody3D

@onready var raycast = $RayCast3D
@onready var target = get_node("/root/main/PlayerCharacter")
@onready var anim_player = $Zombie/AnimationPlayer2
@onready var anim_attack = $Zombie/AnimationPlayer3

var speed = 0.5
const GRAVITY = -9.8
var target_position = Vector3.ZERO
var nav_ready = false
var nav_timer : Timer
var is_attacking = false
var damage_applied = false
var health := 100

func _ready():
	# Pievienojam šo objektu ienaidnieku grupai
	add_to_group("enemies")
	# Sākumā neapstrādājam procesus, līdz nav navigācija gatava
	set_process(false)
	set_physics_process(false)

	# Izveidojam un iestatām taimeri navigācijas gatavības pārbaudei
	nav_timer = Timer.new()
	nav_timer.wait_time = 0.1
	nav_timer.one_shot = false
	nav_timer.autostart = true
	add_child(nav_timer)
	nav_timer.connect("timeout", Callable(self, "_check_nav_ready"))

	# Pieslēdzam animācijas pabeigšanas signālu uzbrukuma animācijai
	anim_attack.connect("animation_finished", Callable(self, "_on_attack_animation_finished"))

	_connect_hit_zones()

func _connect_hit_zones():
	# Savienojam visus trāpījumu apgabalu signālus
	var paths = [
		"Zombie/Skeleton3D/HeadAttachment/Area3D",
		"Zombie/Skeleton3D/ChestAttachment/Area3D",
		"Zombie/Skeleton3D/LeftArmAttachment/Area3D",
		"Zombie/Skeleton3D/RightArmAttachment/Area3D",
		"Zombie/Skeleton3D/LeftForeAttachment/Area3D",
		"Zombie/Skeleton3D/RightForeAttachment/Area3D",
		"Zombie/Skeleton3D/LeftUpLegAttachment3D/Area3D",
		"Zombie/Skeleton3D/RightUpLegAttachment3D2/Area3D",
		"Zombie/Skeleton3D/HipsAttachment/Area3D",
		"Zombie/Skeleton3D/LeftLegAttachment/Area3D",
		"Zombie/Skeleton3D/RightLegAttachment/Area3D"
	]

	for path in paths:
		var area = get_node_or_null(path)
		if area:
			area.connect("body_entered", Callable(self, "_on_body_entered"))
			area.connect("area_entered", Callable(self, "_on_area_entered"))

func _check_nav_ready():
	# Pārbaudām, vai navigācijas karte ir gatava lietošanai
	var nav_map = NavigationServer3D.get_maps()
	if nav_map.size() > 0 and NavigationServer3D.map_get_iteration_id(nav_map[0]) != 0:
		nav_ready = true
		set_process(true)
		set_physics_process(true)
		nav_timer.stop()
		nav_timer.queue_free()
		nav_timer = null

func update_target_location(pos: Vector3) -> void:
	# Atjaunojam mērķa pozīciju tikai X un Z ass komponentes
	target_position.x = pos.x
	target_position.z = pos.z

func _physics_process(delta):
	if not nav_ready:
		return

	if is_attacking:
		# Ja notiek uzbrukums, piemērojam bojājumu noteiktā animācijas brīdī
		var current_time = anim_attack.current_animation_position
		if not damage_applied and current_time >= 0.6667:
			_apply_damage_if_possible()
			damage_applied = true

		velocity = Vector3.ZERO
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("player"):
			velocity = Vector3.ZERO
			velocity.y += GRAVITY * delta
			_stop_walk_animation()
			_play_attack_animation()
			move_and_slide()
			return

	var move_target = Vector3(target_position.x, global_transform.origin.y, target_position.z)
	var direction = (move_target - global_transform.origin).normalized()

	var flat_target = move_target
	flat_target.y = global_transform.origin.y
	look_at(flat_target, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)  # Noņem, ja modelis skatās pareizajā virzienā

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y += GRAVITY * delta

	if direction.length() > 0.1:
		_play_walk_animation()
	else:
		_stop_walk_animation()

	move_and_slide()

func _play_walk_animation():
	# Atskaņo staigāšanas animāciju, ja tā nav ieslēgta
	if not anim_player.is_playing() or anim_player.current_animation != "Walk":
		anim_player.play("Walk")

func _stop_walk_animation():
	# Apstādam staigāšanas animāciju, ja tā tiek atskaņota
	if anim_player.is_playing():
		anim_player.stop()

func _play_attack_animation():
	# Uzsāk uzbrukuma animāciju
	if not is_attacking:
		is_attacking = true
		damage_applied = false
		anim_attack.play("Punching")

func _on_attack_animation_finished(anim_name: String):
	# Kad uzbrukuma animācija pabeigta, atzīmē to
	if anim_name == "Punching":
		is_attacking = false

func _apply_damage_if_possible():
	# Piemēro bojājumus spēlētājam, ja tas ir uzstādīts un atrodas kolīzijā
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(15)

# Apstrādā ķermeņa trāpījumus (ja trāpījums ir ķermenis)
func _on_body_entered(body: Node):
	if body.name != "lightbullet":
		return
	_process_hit(body)

# Apstrādā trāpījumus, ja trāpījums ir Area3D
func _on_area_entered(area: Area3D):
	if area.name != "lightbullet":
		return
	_process_hit(area)

func _process_hit(hit_node: Node):
	# Atrodam virsmezglu, kas satur "Attachment" vārdā
	var attachment = get_parent_attachment_of_area(hit_node)
	if attachment == null:
		return

	var part_name = attachment.name

	# Bojājumu karte atkarībā no trāpītās ķermeņa daļas
	var damage_map = {
		"HeadAttachment": 80,
		"ChestAttachment": 40,
		"LeftArmAttachment": 15,
		"RightArmAttachment": 15,
		"LeftForeAttachment": 5,
		"RightForeAttachment": 5,
		"LeftUpLegAttachment3D": 15,
		"RightUpLegAttachment3D2": 15,
		"HipsAttachment": 20,
		"LeftLegAttachment": 5,
		"RightLegAttachment": 5
	}

	var damage = damage_map.get(part_name, 0)
	if damage > 0:
		health -= damage
		if health <= 0:
			queue_free()

func get_parent_attachment_of_area(area_node: Node) -> Node:
	# Atrod tuvāko virsmezglu, kura nosaukums beidzas ar "Attachment"
	var current = area_node
	while current != null:
		if current.name.ends_with("Attachment"):
			return current
		current = current.get_parent()
	return null
