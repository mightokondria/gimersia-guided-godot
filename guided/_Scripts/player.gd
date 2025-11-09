extends CharacterBody2D

# --- KONSTANTA GERAKAN DASAR ---
const MAX_SPEED = 150.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 2000.0
const FRICTION = 900.0

# --- KONSTANTA DASH ---
const DASH_SPEED = 600.0
const DASH_DURATION = 0.15
var is_dashing = false
var dash_time_left = 0.0

# --- KONSTANTA WALL GRAB ---
const MAX_STAMINA = 2.50
const CLIMB_SPEED = 75.0
const WALL_JUMP_PUSHBACK = 500.0
var current_stamina = MAX_STAMINA
var is_wall_sliding = false



# --- VARIABEL POWER-UP (KUNCI SKILL) ---
var max_jumps = 1
var can_dash = false
var can_wall_grab = false

# --- VARIABEL STATUS LAINNYA ---
var jumps_made = 0
var was_on_floor = true

# --- REFERENSI NODE (WAJIB SESUAI NAMA DI SCENE) ---
@onready var coyote_timer = $CoyoteTimer
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var sprite = $Sprite2D

# --- VARIABEL KAMERA ---
@export var camera : Camera2D

# Ambil nilai gravitasi dari Project Settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# =========================================
	# 0. LOGIKA DASH (Prioritas Tertinggi)
	# =========================================
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
			velocity.x = 0
		else:
			velocity.y = 0 # Abaikan gravitasi saat dash
			move_and_slide()
			return # STOP: Jangan jalankan logika lain saat dashing

	# Input Dash
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer.is_stopped():
		is_dashing = true
		dash_time_left = DASH_DURATION
		dash_cooldown_timer.start()
		# --- TAMBAHAN BARU: PANGGIL SHAKE ---
		if camera and camera.has_method("start_shake"):
			# intensity=5.0, decay=15.0 (getaran cepat & tajam)
			camera.start_shake(5.0, 15.0) 
			# ------------------------------------
		
		# Dash ke arah hadap sprite
		var dash_dir = -1.0 if sprite.flip_h else 1.0
		velocity.x = dash_dir * DASH_SPEED
		return # Mulai dash frame ini juga

	# =========================================
	# 1. DETEKSI INPUT & DINDING
	# =========================================
	# Gunakan "move_left"/"move_right" alih-alih "ui_left"/"ui_right" agar konsisten dengan Input Map
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var climb_dir = Input.get_axis("ui_up", "ui_down")
	
	var is_pushing_wall = false
	if is_on_wall():
		var normal = get_wall_normal()
		# Cek apakah menekan tombol KE ARAH dinding
		if (normal.x < 0 and input_dir > 0) or (normal.x > 0 and input_dir < 0):
			is_pushing_wall = true

	# =========================================
	# 2. LOGIKA WALL GRAB & STAMINA
	# =========================================
	if is_on_floor():
		current_stamina = MAX_STAMINA
		jumps_made = 0
		is_wall_sliding = false

	# Syarat Wall Grab: Punya skill + Tekan arah dinding + Di udara + Ada stamina
	if can_wall_grab and is_pushing_wall and not is_on_floor() and current_stamina > 0:
		is_wall_sliding = true
		if climb_dir != 0:
			velocity.y = climb_dir * CLIMB_SPEED
			current_stamina -= delta * 1.5 # Gerak lebih boros
		else:
			velocity.y = 0 # Diam
			current_stamina -= delta
	else:
		is_wall_sliding = false
		# Terapkan gravitasi HANYA jika TIDAK sedang wall grab
		velocity.y += gravity * delta

	# =========================================
	# 3. LOGIKA LOMPAT
	# =========================================
	# Gunakan "jump" alih-alih "ui_accept" agar konsisten
	if Input.is_action_just_pressed("ui_accept"):
		# A. Lompat Normal (Lantai / Coyote)
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jumps_made = 1
		# B. Wall Jump
		elif is_wall_sliding:
			velocity.y = JUMP_VELOCITY
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSHBACK
			current_stamina -= 1.0 # Kuras stamina instan
		# C. Double Jump
		elif jumps_made < max_jumps:
			velocity.y = JUMP_VELOCITY * 0.8 # Sedikit lebih lemah
			jumps_made += 1

	# =========================================
	# 4. GERAKAN HORIZONTAL
	# =========================================
	# Hanya boleh gerak kiri/kanan jika TIDAK sedang wall sliding
	if not is_wall_sliding:
		if input_dir:
			velocity.x = move_toward(velocity.x, input_dir * MAX_SPEED, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# =========================================
	# 5. FINISH & ANIMASI
	# =========================================
	_update_animation() # Panggil fungsi animasi
	move_and_slide()

	# Logika Coyote Time
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start()
	was_on_floor = is_on_floor()

# --- FUNGSI ANIMASI BARU (Agar Rapi) ---
func _update_animation():
	if is_dashing:
		# sprite.play("dash") # Aktifkan jika sudah punya animasi dash
		return

	if is_wall_sliding:
		# sprite.play("wall_slide") # Aktifkan jika sudah punya animasi wall_slide
		sprite.flip_h = get_wall_normal().x > 0 # Selalu menghadap dinding
		return

	# Animasi dasar (Lompat, Jatuh, Lari, Diam)
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			#print("I'm falling")
			sprite.play("fall")
	else:
		if velocity.x != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

	# Flip sprite saat bergerak biasa
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

# --- FUNGSI POWER-UP ---
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
