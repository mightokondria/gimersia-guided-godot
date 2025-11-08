extends CharacterBody2D

# Kecepatan lari karakter
const MAX_SPEED = 300.0
# Kekuatan lompat (harus negatif karena di Godot, Y negatif itu ke ATAS)
const JUMP_VELOCITY = -400.0
#Akselerasi Awal 
const ACCELERATION = 1500.0
#Akselerasi Akhir
const FRICTION = 1000.0

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

	# 3. Dapatkan arah input (kiri/kanan).
	# "ui_left" (panah kiri/A) bernilai -1, "ui_right" (panah kanan/D) bernilai 1.
	# Jika tidak ditekan, direction bernilai 0.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# 4. Terapkan gerakan.
	if direction:
			# --- AKSELERASI AWAL ---
		# Gerakkan velocity.x SEBESAR ACCELERATION * delta
		# MENUNJU target (direction * MAX_SPEED)
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		# --- AKSELERASI AKHIR (FRIKSI) ---
		# Gerakkan velocity.x SEBESAR FRICTION * delta
		# MENUNJU target (0)
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	# 5. Fungsi sakti bawaan Godot untuk menggerakkan CharacterBody2D
	# berdasarkan nilai 'velocity' yang sudah kita hitung di atas.
	move_and_slide()
	
	# ... (kode akselerasi/friksi Anda) ...


	# ------------------------------------
	# --- LOGIKA COYOTE TIME DIMULAI DARI SINI ---
	# ------------------------------------
	
	# Cek apakah kita BARU SAJA meninggalkan lantai?
	# (Frame lalu di lantai TAPI frame ini di udara)
	var just_left_floor = was_on_floor and not is_on_floor()

	if just_left_floor:
		# Kita hanya ingin menyalakan timer jika kita "jatuh" (velocity.y positif),
		# BUKAN jika kita "lompat" (velocity.y negatif).
		if velocity.y >= 0:
			coyote_timer.start() # Mulai hitung mundur 0.15 detik!

	# "Ingat" status lantai kita untuk pengecekan di frame berikutnya
	was_on_floor = is_on_floor()
