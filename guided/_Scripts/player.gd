extends CharacterBody2D

# Kecepatan lari karakter
const MAX_SPEED = 150.0
# Kekuatan lompat (harus negatif karena di Godot, Y negatif itu ke ATAS)
const JUMP_VELOCITY = -300.0
#Akselerasi Awal 
const ACCELERATION = 2000.0
#Akselerasi Akhir
const FRICTION = 900.0

# --- Variabel Power-up ---
var max_jumps = 1  # Player MULAI dengan 1x lompat
var jumps_made = 0   # Counter untuk melacak lompatan

# WAJIB: Ambil referensi ke node Timer yang baru kita buat
@onready var coyote_timer: Timer = $CoyoteTimer

# Variabel "ingatan" untuk tahu apakah kita DI LANTAI pada frame SEBELUMNYA
var was_on_floor: bool = true

# Ambil nilai gravitasi dari pengaturan proyek agar konsisten
# (Project Settings -> Physics -> 2d -> Default Gravity)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# 1. Tambahkan gravitasi jika karakter sedang di udara
	if not is_on_floor():
		velocity.y += gravity * delta

# 2. Handle Lompat.
	if Input.is_action_just_pressed("ui_accept"):
		# Syarat baru: Boleh lompat JIKA di lantai ATAU coyote timer masih jalan
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop() # WAJIB: Langsung hentikan timer jika kita lompat
			jumps_made = 1 # Ini lompatan PERTAMA kita
			
			# KONDISI 2: Lompatan di Udara (Double Jump, dll)
		elif jumps_made < max_jumps:
			velocity.y = JUMP_VELOCITY # Anda bisa buat lebih lemah: JUMP_VELOCITY * 0.8
			jumps_made += 1
	# 3. Dapatkan arah input (kiri/kanan).
	# "ui_left" (panah kiri/A) bernilai -1, "ui_right" (panah kanan/D) bernilai 1.
	# Jika tidak ditekan, direction bernilai 0.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# 4. Terapkan gerakan.
	if direction:
			# --- AKSELERASI AWAL ---
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		# --- AKSELERASI AKHIR (FRIKSI) ---

		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	# 5. Fungsi sakti bawaan Godot untuk menggerakkan CharacterBody2D
	# berdasarkan nilai 'velocity' yang sudah kita hitung di atas.
	move_and_slide()
	# ------------------------------------
	# --- LOGIKA DI AKHIR FRAME ---
	# (PENTING: Cek status lantai SETELAH move_and_slide)
	# ------------------------------------

	var on_floor_now = is_on_floor() # Cek status lantai saat ini
	# Jika kita di lantai (atau baru mendarat)
	if on_floor_now:
		jumps_made = 0 # Reset counter lompatan
	# ------------------------------------
	# LOGIKA COYOTE TIME DIMULAI DARI SINI
	# ------------------------------------
	# Cek apakah kita BARU SAJA meninggalkan lantai?
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
