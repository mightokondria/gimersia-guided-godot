extends CharacterBody2D

# Kecepatan lari karakter
const MAX_SPEED = 150.0
# Kekuatan lompat (harus negatif karena di Godot, Y negatif itu ke ATAS)
const JUMP_VELOCITY = -400.0
#Akselerasi Awal 
const ACCELERATION = 2000.0
#Akselerasi Akhir
const FRICTION = 900.0

# --- Variabel Power-up ---
var max_jumps = 1  # Player MULAI dengan 1x lompat
var jumps_made = 0   # Counter untuk melacak lompatan
var can_dash = false  # <--- KUNCI: Mulai sebagai 'false'
# --------------------

# --- POWER-UP: WALL GRAB ---
var can_wall_grab = false           # Kunci skill, awal = false
const WALL_SLIDE_GRAVITY = 0.0      # Gravitasi saat nempel (0 = diam total)
const MAX_STAMINA = 2.50            # Durasi maksimal nempel (detik)
const CLIMB_SPEED = 75.0           # Kecepatan naik/turun di dinding
const WALL_JUMP_PUSHBACK = 500.0    # Kekuatan dorongan menjauh dari dinding saat wall jump

var current_stamina = MAX_STAMINA
var is_wall_sliding = false         # Status apakah sedang nempel dinding
# ---------------------------

# --- Variabel Dash ---
const DASH_SPEED = 600.0
const DASH_DURATION = 0.15 # Berapa lama dash berlangsung (dalam detik)
var is_dashing = false
var dash_time_left = 0.0
# --------------------

# WAJIB: Ambil referensi ke node Timer yang baru kita buat
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer


# Variabel "ingatan" untuk tahu apakah kita DI LANTAI pada frame SEBELUMNYA
var was_on_floor: bool = true

# Ambil nilai gravitasi dari pengaturan proyek agar konsisten
# (Project Settings -> Physics -> 2d -> Default Gravity)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# ------------------------------------
	# --- LOGIKA DASH (Jalankan Paling Pertama) ---
	# ------------------------------------
	
	# Cek apakah sedang dalam kondisi dash
	if is_dashing:
		#Kurangi sisa waktu dash
		dash_time_left -= delta
		if dash_time_left <= 0:
			#waktu dash habis, Hentikan dash
			is_dashing = false
			velocity.x = 0 
			velocity.y = 0
		else:
			velocity.y = 0 #abaikan grativasi
			move_and_slide()
			return # <--- PENTING! Lewati semua sisa kode di _physics_process
		
	# Cek input untuk MEMULAI dash
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer.is_stopped():
		is_dashing = true
		dash_time_left = DASH_DURATION
		dash_cooldown_timer.start() #Mulai cooldown 1 detik
		
		#tentukan arah dash
		#Kita akan pakai arah hadap sprite (flip_h)
		var dash_direction = 1.0
		if $Sprite2D.flip_h:
			dash_direction = -1.0
			
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0 # Abaikan gravitasi saat mulai dash

	if not is_on_floor():
		velocity.y += gravity * delta
		
	# =========================================
	# 1. DETEKSI DINDING & INPUT PLAYER
	# =========================================
	var input_direction = Input.get_axis("ui_left", "ui_right")
	var climb_direction = Input.get_axis("ui_up", "ui_down") # W/S atau Panah Atas/Bawah
	
	# Cek apakah player menekan tombol KE ARAH dinding?
	var is_pushing_wall = false
	if is_on_wall():
		var wall_normal = get_wall_normal()
		# Dinding di KANAN (normal -1) dan tekan KANAN (input 1)
		if wall_normal.x < 0 and input_direction > 0:
			is_pushing_wall = true
		# Dinding di KIRI (normal 1) dan tekan KIRI (input -1)
		elif wall_normal.x > 0 and input_direction < 0:
			is_pushing_wall = true
			
	# =========================================
	# 2. LOGIKA WALL GRAB & STAMINA
	# =========================================
	# Reset stamina jika menyentuh tanah
	if is_on_floor():
		current_stamina = MAX_STAMINA
		jumps_made = 0
		is_wall_sliding = false
		
	# Cek syarat masuk kondisi Wall Grab:
	# - Harus punya skill (can_wall_grab == true)
	# - Harus sedang menekan ke arah dinding (is_pushing_wall == true)
	# - Tidak sedang di tanah (not is_on_floor())
	# - Masih punya stamina (current_stamina > 0)
	if can_wall_grab and is_pushing_wall and not is_on_floor() and current_stamina > 0:
		is_wall_sliding = true
		
		# Atur gerakan vertikal (naik/turun)
		if climb_direction != 0:
			velocity.y = climb_direction * CLIMB_SPEED
			current_stamina -= delta * 1.5 # Gerak lebih boros stamina
			
		else:
			velocity.y = 0 # Diam menempel
			current_stamina -= delta       # Diam lebih hemat stamina
	else:
		is_wall_sliding = false
		# Jika tidak wall grab, terapkan GRAVITASI normal
		velocity.y += gravity * delta
	
	# =========================================
	# 3. LOGIKA LOMPAT (Termasuk Wall Jump)
	# =========================================
	
	if Input.is_action_just_pressed("ui_accept"):
		# KONDISI A: Lompat Biasa (dari tanah / coyote time)
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop() 
			jumps_made = 1
			
		# KONDISI B: Wall Jump (saat sedang wall sliding)
		elif is_wall_sliding:
			velocity.y = JUMP_VELOCITY # Dorong ke atas
			# Dorong menjauh dari dinding (penting agar tidak langsung nempel lagi)
			velocity.x = get_wall_normal().x * WALL_JUMP_PUSHBACK
			# Wall jump menguras stamina instan
			current_stamina -= 1.0
			
		# KONDISI C: Double Jump (di udara)
		elif jumps_made < max_jumps:
			velocity.y = JUMP_VELOCITY # Anda bisa buat lebih lemah: JUMP_VELOCITY * 0.8
			jumps_made += 1
	
	
	# =========================================
	# 4. GERAKAN HORIZONTAL (Kiri/Kanan)
	# =========================================
	# Kita HANYA boleh bergerak kiri/kanan jika TIDAK sedang wall sliding.
	# Jika sedang wall sliding, gerakan horizontal dikunci oleh tembok.
	if not is_wall_sliding:
		velocity.x = move_toward(velocity.x, input_direction * MAX_SPEED, ACCELERATION * delta)
		# Jangan lupa flip sprite
		if input_direction > 0: $Sprite2D.flip_h = false
		elif input_direction < 0: $Sprite2D.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	var direction = Input.get_axis("ui_left", "ui_right")
	

	if direction:
			# --- AKSELERASI AWAL ---
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
		if direction > 0:
			$Sprite2D.flip_h = false # Hadap kanan
		elif direction < 0:
			$Sprite2D.flip_h = true # Hadap kiri
	else:
		# --- AKSELERASI AKHIR (FRIKSI) ---

		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()

	var on_floor_now = is_on_floor() # Cek status lantai saat ini
	if on_floor_now:
		jumps_made = 0 # Reset counter lompatan
	var just_left_floor = was_on_floor and not is_on_floor()
	if just_left_floor:
		if velocity.y >= 0:
			coyote_timer.start() # Mulai hitung mundur 0.15 detik!
	was_on_floor = is_on_floor()
	
# Fungsi ini akan dipanggil oleh item power-up
func enable_double_jump():
	if max_jumps < 2: # Pastikan kita tidak mengaktifkannya berkali-kali
		max_jumps = 2
		print("KEMAMPUAN DOUBLE JUMP AKTIF!")
		# Di sini Anda bisa menambahkan efek suara atau partikel
		

# Fungsi ini akan dipanggil oleh item power-up
func enable_dash():
	if not can_dash:
		can_dash = true
		print("KEMAMPUAN DASH AKTIF!")
		# Anda bisa tambahkan efek suara/partikel di sini

# Fungsi ini akan dipanggil oleh item power-up
func enable_wall_grab():
	if not can_wall_grab:
		can_wall_grab = true
		print("KEMAMPUAN WALL GRAB AKTIF!")
