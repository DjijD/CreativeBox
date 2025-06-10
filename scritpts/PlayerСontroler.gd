extends CharacterBody3D

var speed = 7.0
var is_sprinting = 0.0
const SPEED_INITIAL = 7.0
const SPEED_SPRINT_MULT = 1.5
const SPEED_SMOOTH = 0.5
const CAM_SMOOTH = 0.005
const JUMP_VELOCITY = 4.5

const VERTICAL_SWAY_INTENSITY = 0.08
const SWAY_SPEED = 8.0
const HORIZONTAL_SWAY_INTENSITY = 0.08
var sway_timer = 0.0
var is_walking = false
var initial_camera_position = Vector3.ZERO

var health = 100.0
const MAX_HEALTH = 100.0

var noclip_enabled := false
var fall_start_y = 0.0
var was_on_floor = true
var spawn_position = Vector3.ZERO
var selected_slot_index := 0

@onready var slots_manager = get_node("/root/main/PlayerCharacter/HUD/slots")
@onready var weapon_handler = $Camera3D/HeldWeaponController

func _ready():
	# Pievienojam spēlētāju grupai un nofiksējam peli uz logu
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	initial_camera_position = $Camera3D.position
	# Pārslēdzam procesus atkarībā no noclip režīma
	set_process(noclip_enabled)
	set_physics_process(!noclip_enabled)
	spawn_position = global_transform.origin

func _input(event):
	# Pārslēdz noclip režīmu ar taustiņu
	if event.is_action_pressed("toggle_noclip"):
		noclip_enabled = !noclip_enabled
		set_process(noclip_enabled)
		set_physics_process(!noclip_enabled)

	# Izvēlas inventāra slotu ar ciparu taustiņiem
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: select_slot(0)
			KEY_2: select_slot(1)
			KEY_3: select_slot(2)
			KEY_4: select_slot(3)

	# Izvēlas slotu ar peles ritināšanu
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_slot((selected_slot_index - 1) % 4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_slot((selected_slot_index + 1) % 4)

	# Kameras pagrieziens ar peles kustību
	if event is InputEventMouseMotion:
		var dx = -event.relative.x * 0.005
		var dy = -event.relative.y * 0.005
		var cam = $Camera3D
		if cam:
			rotate_y(dx)
			cam.rotation.x = clamp(cam.rotation.x + dy, -PI / 2.1, PI / 2.1)

func select_slot(index: int):
	selected_slot_index = index
	if is_instance_valid(slots_manager):
		var slot_name = "slot" + str(index + 1)
		slots_manager.update_selection(slot_name)
		update_weapon_visibility(slot_name)

func update_weapon_visibility(slot_name: String):
	var slot_data = slots_manager.slots_data.get(slot_name)
	# Rāda ieroču ja slotā ir derīgs priekšmets (piem., slot3)
	if slot_name == "slot3" and slot_data and slot_data.item_id != null:
		weapon_handler.show_weapon(slot_data.item_id)
	else:
		weapon_handler.remove_weapon()

func _physics_process(delta: float) -> void:
	if noclip_enabled:
		# Noclip režīmā atgriežas fizika
		return

	var on_floor_now = is_on_floor()

	# Bojājumi no krišanas, ja ir nokritis no augstuma
	if on_floor_now:
		if not was_on_floor:
			var fall_distance = fall_start_y - global_transform.origin.y
			if fall_distance > 5.0:
				var damage = int((fall_distance - 5.0) * 2)
				take_damage(damage)
		was_on_floor = true
	else:
		if was_on_floor:
			fall_start_y = global_transform.origin.y
		was_on_floor = false

	# Ja veselība beigusies, atjauno spēlētāju
	if health <= 0:
		respawn()

	# Ja spēlētājs nav gaisā, apstrādā kustību
	if not on_floor_now:
		velocity += get_gravity() * delta
		is_walking = false
	else:
		speed = SPEED_INITIAL
		is_sprinting = 0.0

		var input_dir := Vector2.ZERO
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1
		if Input.is_action_pressed("sprint"):
			is_sprinting = 1.0
			speed *= SPEED_SPRINT_MULT

		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction.length() > 0:
			velocity.x = move_toward(velocity.x, direction.x * speed, SPEED_SMOOTH)
			velocity.z = move_toward(velocity.z, direction.z * speed, SPEED_SMOOTH)
			is_walking = true
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_SMOOTH)
			velocity.z = move_toward(velocity.z, 0, SPEED_SMOOTH)
			is_walking = false

	# Lēciens, ja nospiesta atbilstošā poga un spēlētājs uz zemes
	if Input.is_action_just_pressed("jump") and on_floor_now:
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	# Kamera kustas šūpojoties soļojot
	var cam = $Camera3D
	if on_floor_now and is_walking:
		sway_timer += delta * SWAY_SPEED
		var sway_mult = is_sprinting * SPEED_SPRINT_MULT + (1.0 - is_sprinting)
		var sway_y = abs(sin(sway_timer * sway_mult) * VERTICAL_SWAY_INTENSITY)
		var sway_x = sin(sway_timer * sway_mult) * HORIZONTAL_SWAY_INTENSITY

		cam.position.y = move_toward(cam.position.y, initial_camera_position.y + sway_y, CAM_SMOOTH)
		cam.position.x = move_toward(cam.position.x, initial_camera_position.x + sway_x, CAM_SMOOTH)
	else:
		cam.position.x = move_toward(cam.position.x, initial_camera_position.x, CAM_SMOOTH)
		cam.position.y = move_toward(cam.position.y, initial_camera_position.y, CAM_SMOOTH)

func _process(delta: float) -> void:
	if noclip_enabled:
		# Noclip režīmā pārvieto spēlētāju pēc kameras virziena
		var cam = $Camera3D
		var input_dir := Vector3.ZERO

		if Input.is_action_pressed("move_forward"):
			input_dir -= cam.global_transform.basis.z
		if Input.is_action_pressed("move_back"):
			input_dir += cam.global_transform.basis.z
		if Input.is_action_pressed("move_left"):
			input_dir -= cam.global_transform.basis.x
		if Input.is_action_pressed("move_right"):
			input_dir += cam.global_transform.basis.x
		if Input.is_action_pressed("jump"):
			input_dir += Vector3.UP

		var speed_mult := SPEED_INITIAL
		if Input.is_action_pressed("sprint"):
			speed_mult *= SPEED_SPRINT_MULT

		global_transform.origin += input_dir.normalized() * speed_mult * delta

func take_damage(amount: int) -> void:
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)
	print("Saņemti bojājumi: %d, Veselība tagad: %d" % [amount, health])

func respawn() -> void:
	print("Spēlētājs nomira, atjauno pozīciju...")
	health = MAX_HEALTH
	global_transform.origin = spawn_position
	velocity = Vector3.ZERO

func get_slots_node():
	return slots_manager
