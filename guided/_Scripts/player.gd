extends CharacterBody2D

# --- KONSTANTA GERAKAN DASAR ---
const MAX_SPEED = 800.0
const JUMP_VELOCITY = -1400.0
const ACCELERATION = 8000.0
const AIR_ACCELERATION = 6000.0 
const FRICTION = 5000.0
const AIR_FRICTION = 1000.0

# --- KONSTANTA DASH ---
const DASH_SPEED = 2500.0
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

# --- REFERENSI NODE (WAJIB SESUAI NAMA DI SCENE) ---
@onready var coyote_timer = $CoyoteTimer
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var sprite = $Sprite2D
@onready var camera: Camera2D = get_tree().get_first_node_in_group("Camera")

# Ambil nilai gravitasi dari Project Settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var is_cutscene = false

func _physics_process(delta):
	
	# --- [TAMBAHAN PENTING DI PALING ATAS] ---
	if is_cutscene:
		# Jika cutscene, player hanya kena gravitasi agar tidak melayang
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			
		# Nol-kan kecepatan horizontal agar diam
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
		move_and_slide()
		_update_animation()
		return # STOP: Jangan proses input apapun di bawah ini!
	# -----------------------------------------
	
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
		# Dash ke arah hadap sprite
		var dash_dir = -1.0 if sprite.flip_h else 1.0
		velocity.x = dash_dir * DASH_SPEED
		#triggershake
		camera.trigger_shake(150.0)
		
		return # Mulai dash frame ini juga

	# =========================================
	# 1. DETEKSI INPUT & DINDING
	# =========================================
	# Gunakan "move_left"/"move_right" alih-alih "ui_left"/"ui_right" agar konsisten dengan Input Map
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var climb_dir = Input.get_axis("ui_up", "ui_down")
	
	var _is_pushing_wall = false
	if is_on_wall():
		var normal = get_wall_normal()
		# Cek apakah menekan tombol KE ARAH dinding
		if (normal.x < 0 and input_dir > 0) or (normal.x > 0 and input_dir < 0):
			_is_pushing_wall = true

	# =========================================
	# 2. LOGIKA WALL GRAB & STAMINA
	# =========================================
	if is_on_floor():
		current_stamina = MAX_STAMINA
		jumps_made = 0
		is_wall_sliding = false
		
		
	# [UBAH BAGIAN INI]
	# (Kita asumsikan Anda ingin grab pakai tombol "grab" khusus, bukan otomatis)
	var is_holding_grab_key = Input.is_action_pressed("grip")

	# Syarat: Punya skill + DI DINDING + TEKAN GRAB + DI UDARA + Punya stamina
	if can_wall_grab and is_on_wall() and is_holding_grab_key and not is_on_floor() and current_stamina > 0:
		is_wall_sliding = true
		# Reset jatah lompatan saat berhasil nempel
		jumps_made = 0
		
		if climb_dir != 0:
			velocity.y = climb_dir * CLIMB_SPEED
			current_stamina -= delta * 1.5 # Gerak lebih boros
		else:
			velocity.y = 0 # Diam
			current_stamina -= delta
	else:
		is_wall_sliding = false
		# Terapkan gravitasi HANYA jika TIDAK sedang wall grab
		var gravity_multiplier = 1.0
		if velocity.y > 0: # Jika sedang jatuh ke bawah
			gravity_multiplier = 1.5 # Jatuh 1.5x lebih cepat
			
		velocity.y += gravity * gravity_multiplier * delta

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
			current_stamina -= 1.0
			
			# [UBAH] Anggap wall jump sebagai lompatan PERTAMA (jumps_made = 1)
			# Ini mengizinkan kita melakukan double jump (jumps_made = 2) nanti
			jumps_made = 1
		# C. Double Jump
		elif jumps_made < max_jumps:
			velocity.y = JUMP_VELOCITY * 0.8 # Sedikit lebih lemah
			jumps_made += 1

	# =========================================
	# 4. GERAKAN HORIZONTAL
	# =========================================
	# Hanya boleh gerak kiri/kanan jika TIDAK sedang wall sliding
	if not is_wall_sliding:
		# Tentukan nilai akselerasi & friksi yang dipakai saat ini
		var _current_accel = ACCELERATION
		var _current_friction = FRICTION
		
		if not is_on_floor():
			_current_accel = AIR_ACCELERATION
			_current_friction = AIR_FRICTION
		
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
		
		
# Fungsi untuk dipanggil oleh AnimationPlayer
func set_cutscene_state(state: bool):
	is_cutscene = state
