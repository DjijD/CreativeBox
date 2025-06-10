extends CharacterBody3D

@onready var raycast = $RayCast3D
@onready var target = get_node("/root/main/PlayerCharacter")
@onready var anim_player = $FastZombie/AnimationPlayer2
@onready var anim_attack = $FastZombie/AnimationPlayer3

var speed = 4.0
const GRAVITY = -9.8
var target_position = Vector3.ZERO
var nav_ready = false
var nav_timer : Timer
var is_attacking = false
var damage_applied = false
var health := 75

func _ready():
	add_to_group("enemies")
	set_process(false)
	set_physics_process(false)

	# Navigācijas sistēmas gatavības pārbaudes taimeris
	nav_timer = Timer.new()
	nav_timer.wait_time = 0.1
	nav_timer.one_shot = false
	nav_timer.autostart = true
	add_child(nav_timer)
	nav_timer.connect("timeout", Callable(self, "_check_nav_ready"))

	# Uzbrukuma animācijas beigšana
	anim_attack.connect("animation_finished", Callable(self, "_on_attack_animation_finished"))

func _check_nav_ready():
	var nav_map = NavigationServer3D.get_maps()
	if nav_map.size() > 0 and NavigationServer3D.map_get_iteration_id(nav_map[0]) != 0:
		nav_ready = true
		set_process(true)
		set_physics_process(true)
		nav_timer.stop()
		nav_timer.queue_free()
		nav_timer = null

# Atjaunina mērķa pozīciju (X un Z)
func update_target_location(pos: Vector3) -> void:
	target_position.x = pos.x
	target_position.z = pos.z

func _physics_process(delta):
	if not nav_ready:
		return

	# Uzbrukuma laikā
	if is_attacking:
		var current_time = anim_attack.current_animation_position
		if not damage_applied and current_time >= 0.6667:
			_apply_damage_if_possible()
			damage_applied = true

		velocity = Vector3.ZERO
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Ja spēlētājs tiek detektēts ar staru
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("player"):
			velocity = Vector3.ZERO
			velocity.y += GRAVITY * delta
			_stop_walk_animation()
			_play_attack_animation()
			move_and_slide()
			return

	# Kustības aprēķins uz mērķi
	var move_target = Vector3(target_position.x, global_transform.origin.y, target_position.z)
	var direction = (move_target - global_transform.origin).normalized()

	var flat_target = move_target
	flat_target.y = global_transform.origin.y
	look_at(flat_target, Vector3.UP)
	rotate_object_local(Vector3.UP, PI) # Pagrieziens uz 180°

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y += GRAVITY * delta

	if direction.length() > 0.1:
		_play_walk_animation()
	else:
		_stop_walk_animation()

	move_and_slide()

# Atskaņo soļu animāciju
func _play_walk_animation():
	if not anim_player.is_playing() or anim_player.current_animation != "Walk":
		anim_player.play("Walk")

# Apstādina soļu animāciju
func _stop_walk_animation():
	if anim_player.is_playing():
		anim_player.stop()

# Uzsāk uzbrukuma animāciju
func _play_attack_animation():
	if not is_attacking:
		is_attacking = true
		damage_applied = false
		anim_attack.play("Punching")

# Kad uzbrukuma animācija beigusies
func _on_attack_animation_finished(anim_name: String):
	if anim_name == "Punching":
		is_attacking = false

# Pārbauda un pielieto bojājumus, ja spēlētājs ir tuvumā
func _apply_damage_if_possible():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(20)

# Sabiedrībā pieejama metode, lai pieņemtos bojājumus (piemēram, no naža)
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()
	else:
		_play_hurt_animation()

# Nāves funkcija
func _die():
	queue_free() # Var pievienot nāves animāciju, skaņas utt.

# Funkcija bojājumu animācijai
func _play_hurt_animation():
	pass # Šeit var pievienot vizuālu vai audio reakciju

# Apstrādā trāpījumu pa konkrētu ķermeņa daļu
func _process_hit(hit_area: Area3D) -> void:
	var attachment = _get_parent_attachment_of_area(hit_area)
	if attachment == null:
		return

	var damage_map = {
		"HeadAttachment": 80,
		"ChestAttachment": 40,
		"LeftArmAttachment": 15,
		"RightArmAttachment": 15,
		"LeftForeAttachment": 5,
		"RightForeAttachment": 5,
		"LeftUpLegAttachment": 15,
		"RightUpLegAttachment": 15,
		"HipsAttachment": 20,
		"LeftLegAttachment": 5,
		"RightLegAttachment": 5
	}

	var damage = damage_map.get(attachment.name, 0)
	if damage > 0:
		take_damage(damage)

# Atrod BoneAttachment3D vecāku mezglu dotajam laukuma objektam
func _get_parent_attachment_of_area(area_node: Node) -> BoneAttachment3D:
	var current = area_node
	while current != null:
		if current is BoneAttachment3D:
			return current
		current = current.get_parent()
	return null
