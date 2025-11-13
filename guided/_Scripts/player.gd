extends CharacterBody2D
@onready var sfx: AudioStreamPlayer2D = $SFX

func play_sfx(file_path: String):
	var stream = load(file_path)
	if stream:
		sfx.stream = stream
		sfx.play()

# --- KONSTANTA GERAKAN DASAR ---
const MAX_SPEED = 600.0
const JUMP_VELOCITY = -1550.0
const ACCELERATION = 8000.0
const AIR_ACCELERATION = 6000.0 
const FRICTION = 5000.0
const AIR_FRICTION = 1000.0

# --- KONSTANTA DASH ---
const DASH_SPEED = 1550.0
const DASH_DURATION = 0.15
var is_dashing = false
var dash_time_left = 0.0

# --- KONSTANTA WALL GRAB ---
const MAX_STAMINA = 3.0
const CLIMB_SPEED = 300.0
const WALL_JUMP_PUSHBACK = 1500.0
var current_stamina = MAX_STAMINA
var is_wall_sliding = false

# --- VARIABEL POWER-UP (KUNCI SKILL) ---
var max_jumps = 1
var can_dash = false
var can_wall_grab = false

# --- VARIABEL STATUS LAINNYA ---
var jumps_made = 0
var was_on_floor = true
var pending_retry_dialog := false

# --- REFERENSI NODE (WAJIB SESUAI NAMA DI SCENE) ---
@onready var coyote_timer = $CoyoteTimer
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var sprite = $Sprite2D
@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")

# Ambil nilai gravitasi dari Project Settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var is_cutscene = false


func _physics_process(delta):
	# --- CUTSCENE MODE ---
	if is_cutscene:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()

		if is_on_floor():
			sprite.play("idle")
		else:
			sprite.play("fall")
		return
	
	# --- DASH LOGIC ---
	if is_dashing:
		play_sfx("res://Audio/SFX/sfx/dash_002.wav")
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
			velocity.x = 0
		else:
			move_and_slide()
			return  # skip logic lain saat dash

	# --- DASH INPUT (horizontal only) ---
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer.is_stopped():
		is_dashing = true
		dash_time_left = DASH_DURATION
		dash_cooldown_timer.start()

		# Kamera shake
		if camera and camera.has_method("start_shake"):
			camera.start_shake(80.0, 150.0)

		# Tentukan arah dash berdasarkan arah hadap sprite
		var dash_dir = -1.0 if sprite.flip_h else 1.0
		velocity = Vector2(dash_dir * DASH_SPEED, 0)

		# Efek tambahan
		if camera and camera.has_method("trigger_shake"):
			camera.trigger_shake()
		Input.start_joy_vibration(0, 0.5, 1.0, 0.3)
		return

	# --- GERAKAN DASAR ---
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var climb_dir = Input.get_axis("ui_up", "ui_down")

	var _is_pushing_wall = false
	if is_on_wall():
		var normal = get_wall_normal()
		if (normal.x < 0 and input_dir > 0) or (normal.x > 0 and input_dir < 0):
			_is_pushing_wall = true

	# --- WALL GRAB ---
	if is_on_floor():
		current_stamina = MAX_STAMINA
		jumps_made = 0
		is_wall_sliding = false

	var is_holding_grab_key = Input.is_action_pressed("grip")

	if can_wall_grab and is_on_wall() and is_holding_grab_key and not is_on_floor() and current_stamina > 0:
		is_wall_sliding = true
		jumps_made = 0

		if climb_dir != 0:
			velocity.y = climb_dir * CLIMB_SPEED
			current_stamina -= delta * 1.5
		else:
			velocity.y = 0
			current_stamina -= delta
	else:
		is_wall_sliding = false
		var gravity_multiplier = 1.0
		if velocity.y > 0:
			gravity_multiplier = 1.5
		velocity.y += gravity * gravity_multiplier * delta

	# --- JUMP LOGIC ---
	if Input.is_action_just_pressed("ui_accept"):
		play_sfx("res://Audio/SFX/sfx/jump.wav")
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jumps_made = 1
		elif is_wall_sliding:
			velocity.y = JUMP_VELOCITY
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSHBACK
			current_stamina -= 1.0
			jumps_made = 1
		elif jumps_made < max_jumps:
			velocity.y = JUMP_VELOCITY * 0.8
			jumps_made += 1

	# --- GERAK HORIZONTAL ---
	if not is_wall_sliding:
		var _current_accel = ACCELERATION
		var _current_friction = FRICTION
		if not is_on_floor():
			_current_accel = AIR_ACCELERATION
			_current_friction = AIR_FRICTION

		if input_dir:
			velocity.x = move_toward(velocity.x, input_dir * MAX_SPEED, _current_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, _current_friction * delta)

	# --- UPDATE ANIMASI ---
	_update_animation()
	move_and_slide()

	# --- COYOTE TIME ---
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start()
	was_on_floor = is_on_floor()


# --- ANIMASI ---
func _update_animation():
	if is_dashing:
		return

	if is_wall_sliding:
		sprite.flip_h = get_wall_normal().x > 0
		return

	if not is_on_floor():
		if velocity.y < 0:
			if jumps_made > 1:
				sprite.play("double_jump")
				play_sfx("res://Audio/SFX/sfx/double jump.wav")
			else:
				sprite.play("jump")
		else:
			sprite.play("fall")
	else:
		if velocity.x != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true


# --- POWER-UP FUNCTIONS ---
func enable_double_jump():
	if max_jumps < 2:
		max_jumps = 2
		print("DOUBLE JUMP AKTIF!")

func enable_dash():
	if not can_dash:
		can_dash = true
		print("DASH AKTIF!")

func enable_wall_grab():
	if not can_wall_grab:
		can_wall_grab = true
		print("WALL GRAB AKTIF!")


# --- CUTSCENE CONTROL ---
func set_cutscene_state(state: bool):
	is_cutscene = state
