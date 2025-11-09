extends Camera2D

@export var player: Node2D
@export var follow_speed: float = 5.0

# --- [BAGIAN 1] VARIABEL SCREEN SHAKE ---
# FastNoiseLite adalah alat bawaan Godot untuk membuat angka acak yang 'mulus'.
# Kita pakai ini agar getaran kamera terasa natural, tidak patah-patah.
@export var shake_noise: FastNoiseLite

# Kekuatan getaran saat ini. Akan berkurang seiring waktu.
var shake_strength: float = 0.0

# Seberapa cepat getaran hilang per detik.
# Nilai 5.0 artinya getaran hilang dalam waktu sekitar 1/5 detik.
var shake_decay: float = 5.0

# Variabel "waktu" internal untuk noise. Kita majukan terus agar angka acaknya berubah.
var noise_i: float = 0.0
# ----------------------------------------

var base_y_position: float
var base_x_position: float
var trigger_y_local: float

func _ready():
	if player == null: print("ERROR KAMERA: Player belum di-assign!")
	base_y_position = global_position.y
	base_x_position = global_position.x
	
	var viewport_rect = get_viewport_rect()
	trigger_y_local = -(viewport_rect.size.y / 2.0) + (viewport_rect.size.y * 0.20)

	# [BAGIAN 2] Setup Noise Otomatis
	# Jika kita lupa memasukkan Noise di Inspector, script ini akan membuatnya sendiri.
	if shake_noise == null:
		shake_noise = FastNoiseLite.new()
		shake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # Tipe noise yang bagus untuk getaran
		shake_noise.frequency = 0.1 # Frekuensi rendah = getaran lebih 'berat'

func _process(delta):
	if player == null: return

	# --- [BAGIAN 3] HITUNG POSISI IDEAL ---
	# Ini adalah logika lama Anda untuk mengikuti player secara vertikal.
	var target_y = base_y_position
	if (player.global_position.y - global_position.y) < trigger_y_local:
		target_y = player.global_position.y - trigger_y_local
	
	var ideal_pos_x = base_x_position
	var ideal_pos_y = lerp(global_position.y, target_y, follow_speed * delta)

	# --- [BAGIAN 4] HITUNG GANGGUAN GETARAN (OFFSET) ---
	var offset_x = 0.0
	var offset_y = 0.0
	
	# Hanya hitung jika ada kekuatan getaran tersisa
	if shake_strength > 0:
		# A. Kurangi kekuatan getaran pelan-pelan (decay)
		shake_strength = move_toward(shake_strength, 0, shake_decay * delta)
		
		# B. Majukan "waktu" noise agar dapat angka acak baru
		noise_i += delta * 30.0 # Angka 30.0 ini kecepatan getarnya
		
		# C. Ambil angka acak dari noise (-1 s/d 1), lalu kalikan dengan kekuatan
		offset_x = shake_noise.get_noise_2d(noise_i, 0.0) * shake_strength
		offset_y = shake_noise.get_noise_2d(0.0, noise_i) * shake_strength

	# --- [BAGIAN 5] TERAPKAN POSISI AKHIR ---
	# Posisi Akhir = Posisi Ideal + Gangguan
	global_position.x = ideal_pos_x + offset_x
	global_position.y = ideal_pos_y + offset_y

# --- [BAGIAN 6] FUNGSI PEMICU ---
# Fungsi ini dipanggil dari luar (misal: oleh Player saat dash)
func start_shake(intensity: float, decay: float = 5.0):
	shake_strength = intensity # Set kekuatan awal (misal: 5.0)
	shake_decay = decay        # Set kecepatan hilang (misal: 15.0 biar cepat hilang)
