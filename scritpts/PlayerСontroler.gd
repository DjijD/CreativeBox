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

# Mainīgie krišanas bojājumiem
var fall_start_y = 0.0
var was_on_floor = true

# Spawna sākuma pozīcija
var spawn_position = Vector3.ZERO

func _ready():
	# Uzstāda peles režīmu, lai kamera varētu grozīties
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Saglabā sākotnējo kameras pozīciju, lai varētu animēt šūpošanos
	initial_camera_position = $Camera3D.position
	
	# Iestata procesus atkarībā no noclip režīma
	set_process(noclip_enabled)
	set_physics_process(!noclip_enabled)
	
	# Saglabā spēlētāja sākotnējo pozīciju respawnam
	spawn_position = global_transform.origin

func _input(event):
	if event.is_action_pressed("toggle_noclip"):
		# Ieslēdz vai izslēdz noclip režīmu
		noclip_enabled = !noclip_enabled
		set_process(noclip_enabled)
		set_physics_process(!noclip_enabled)

	if event is InputEventMouseMotion:
		# Apstrādā peles kustības, lai grozītu kameru un spēlētāju
		var dx = -event.relative.x * 0.005
		var dy = -event.relative.y * 0.005

		var cam = $Camera3D
		if cam:
			rotate_y(dx)
			cam.rotation.x = clamp(cam.rotation.x + dy, -PI / 2.1, PI / 2.1)

func _physics_process(delta: float) -> void:
	if noclip_enabled:
		# Ja noclip ir ieslēgts, neapstrādā fiziku
		return

	var on_floor_now = is_on_floor()

	if on_floor_now:
		if not was_on_floor:
			# Spēlētājs tikko nosēdās - aprēķina krišanas attālumu un bojājumus
			var fall_distance = fall_start_y - global_transform.origin.y
			if fall_distance > 5.0:  # Kritiena augstuma slieksnis
				var damage = int((fall_distance - 5.0) * 2) # Bojājumu formula
				take_damage(damage)
		was_on_floor = true
	else:
		if was_on_floor:
			# Spēlētājs tikai tikko atdalījās no zemes - saglabā sākuma augstumu krišanai
			fall_start_y = global_transform.origin.y
		was_on_floor = false

	# Ja veselība ir zem vai vienāda ar 0, atjauno spēlētāju (respawn)
	if health <= 0:
		respawn()

	if not on_floor_now:
		# Pievieno gravitāciju, ja spēlētājs gaisā
		velocity += get_gravity() * delta
		is_walking = false 
	else:
		# Apstrādā spēlētāja kustību pa zemes virsmu
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

		if direction:
			velocity.x = move_toward(velocity.x, direction.x * speed, SPEED_SMOOTH)
			velocity.z = move_toward(velocity.z, direction.z * speed, SPEED_SMOOTH)
			is_walking = true 
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_SMOOTH)
			velocity.z = move_toward(velocity.z, 0, SPEED_SMOOTH)
			is_walking = false

	if Input.is_action_just_pressed("jump") and on_floor_now:
		# Izpilda lēcienu, ja nospiesta lēciena poga un spēlētājs ir uz zemes
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	if on_floor_now and is_walking:
		# Kamera šūpojas soļošanas laikā (mazs efekts)
		sway_timer += delta * SWAY_SPEED
		var sway_intensity_multiplier = is_sprinting * SPEED_SPRINT_MULT + (1.0 - is_sprinting)
		var vertical_sway_offset = abs(sin(sway_timer * sway_intensity_multiplier) * VERTICAL_SWAY_INTENSITY)
		var horizontal_sway_offset = sin(sway_timer * sway_intensity_multiplier) * HORIZONTAL_SWAY_INTENSITY

		$Camera3D.position.y = move_toward($Camera3D.position.y, initial_camera_position.y + vertical_sway_offset, CAM_SMOOTH)
		$Camera3D.position.x = move_toward($Camera3D.position.x, initial_camera_position.x + horizontal_sway_offset, CAM_SMOOTH)
	else:
		# Atgriež kameru sākotnējā pozīcijā, kad spēlētājs stāv vai lido
		$Camera3D.position.x = move_toward($Camera3D.position.x, initial_camera_position.x, CAM_SMOOTH)
		$Camera3D.position.y = move_toward($Camera3D.position.y, initial_camera_position.y, CAM_SMOOTH)

func _process(delta):
	if noclip_enabled:
		# Noclip režīms - brīva kustība ar kameru
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

		input_dir = input_dir.normalized()
		global_position += input_dir * speed_mult * delta


# Funkcija bojājumu saņemšanai
func take_damage(amount: int) -> void:
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)
	print("Saņemti bojājumi: %d, Veselība tagad: %d" % [amount, health])


# Funkcija spēlētāja respawnam
func respawn() -> void:
	print("Spēlētājs nomira, atjauno pozīciju...")
	health = MAX_HEALTH
	global_transform.origin = spawn_position
	velocity = Vector3.ZERO
