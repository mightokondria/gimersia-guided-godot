extends CharacterBody2D

# Kecepatan lari karakter
const SPEED = 300.0
# Kekuatan lompat (harus negatif karena di Godot, Y negatif itu ke ATAS)
const JUMP_VELOCITY = -400.0

# Ambil nilai gravitasi dari pengaturan proyek agar konsisten
# (Project Settings -> Physics -> 2d -> Default Gravity)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# 1. Tambahkan gravitasi jika karakter sedang di udara
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Lompat.
	# Jika tombol "ui_accept" (biasanya Spasi/Enter) ditekan DAN karakter sedang di lantai
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Dapatkan arah input (kiri/kanan).
	# "ui_left" (panah kiri/A) bernilai -1, "ui_right" (panah kanan/D) bernilai 1.
	# Jika tidak ditekan, direction bernilai 0.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# 4. Terapkan gerakan.
	if direction:
		# Jika ada input, gerakkan karakter ke arah tersebut dengan kecepatan SPEED
		velocity.x = direction * SPEED
	else:
		# Jika tidak ada input, perlambat karakter sampai berhenti (move_toward 0)
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. Fungsi sakti bawaan Godot untuk menggerakkan CharacterBody2D
	# berdasarkan nilai 'velocity' yang sudah kita hitung di atas.
	move_and_slide()
