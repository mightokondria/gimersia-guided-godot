extends Node2D # Atau tipe node root Anda

# --- Referensi Node (Isi di Inspector) ---
@export var player: CharacterBody2D
@export var sensei: CharacterBody2D
@export var sensei_anim_player: AnimationPlayer
@export var dialog_box: CanvasLayer # Script TextBox Anda
@export var camera: Camera2D # Script SmartCamera Anda
@export var stage1_spawn: Marker2D
@export var stage1_finish_line: Area2D
@export var stage2_spawn: Marker2D # Untuk nanti

@onready var info: CanvasLayer = $Info


# --- Variabel Status Game ---

var current_stage = 1
var player_won_race = false
var race_in_progress = false

func _ready():
	info.visible = false
	# Hubungkan sinyal garis finis ke skrip ini
	stage1_finish_line.body_entered.connect(_on_finish_line_entered)
	
	# Mulai alur game
	start_cutscene_1()

# --- ALUR UTAMA (Sesuai Poin Anda) ---

# Poin 1 & 2: Player mengikuti, Sensei menang
func start_cutscene_1():
	player.set_cutscene_state(true) # Matikan kontrol player
	
	# (Opsional) Tampilkan dialog awal
	dialog_box.queue_text("Sensei", "Halo, selamat datang di latihan pertamamu.", "sensei_happy")
	dialog_box.queue_text("cuki", "may", "sensei_happy")
	await dialog_box.finished
	# Sensei menang, player di-reset
	player.global_position = stage1_spawn.global_position
	sensei.global_position = stage1_spawn.global_position
	sensei_anim_player.play("SenseiWalk")
	player.set_cutscene_state(true)
	start_race()

# Memulai balapan yang sesungguhnya
func start_race():
	
	# Reset posisi & status
	player_won_race = false
	race_in_progress = true
	player.global_position = stage1_spawn.global_position
	sensei.global_position = stage1_spawn.global_position
	
	# Mulai balapan!
	sensei_anim_player.play("SenseiWalk") # Pakai animasi yg bisa dikalahkan
	player.set_cutscene_state(false) # Hidupkan kontrol player

# --- Poin 4 & 5: Deteksi Pemenang ---
func _on_finish_line_entered(body):
	# Jika balapan tidak sedang berjalan, abaikan
	if not race_in_progress:
		return
		
	# Cek siapa yang masuk garis finis
	if body.name == "Player":
		player_won_race = true
		race_in_progress = false
		sensei_anim_player.stop() # Hentikan Sensei, Player menang!
		_evaluate_race_result()
		
	elif body.name == "Sensei":
		player_won_race = false
		race_in_progress = false
		player.set_cutscene_state(true) # Kunci Player, Sensei menang!
		_evaluate_race_result()

# --- Poin 4 & 5: Evaluasi Hasil ---
func _evaluate_race_result():
	# Matikan kontrol player sementara
	player.set_cutscene_state(true)

	if player_won_race:
		# Poin 5: Player MENANG, lanjut ke stage 2
		dialog_box.queue_text("Sensei", "Gokil", "player_happy")
		await dialog_box.finished
		
		# Panggil fungsi pindah kamera (dijelaskan di bawah)
		move_camera_to_stage(2)
		
	else:
		#kalah
		dialog_box.queue_text("Sensei", "PAYAH!", "sensei_happy")
		dialog_box.queue_text("Sensei", "nih DASH!", "player_happy")
		await dialog_box.finished
		
		player.enable_dash()
		
		# 1. Munculkan info bar
		info.visible = true
		
		# --- [PERBAIKAN KUNCI] ---
		# Paksa Godot untuk menunggu 1 frame agar info bar sempat tergambar di layar
		await get_tree().process_frame
		# --------------------------
		
		# 2. SEKARANG baru kita tunggu input
		await wait_for_input("ui_accept")
		
		# 3. Sembunyikan lagi info bar-nya
		info.visible = false
		
		# 4. Mulai balapan
		start_race()

# --- Poin 5: Pindah Stage & Kamera ---
func move_camera_to_stage(stage_num):
	var target_pos: Vector2
	
	if stage_num == 2:
		target_pos = stage2_spawn.global_position
	# (tambahkan 'elif stage_num == 3' dst. nanti)

	# Beritahu kamera untuk bergerak
	if camera and camera.has_method("move_to_position"):
		# Kita perlu tambah fungsi 'move_to_position' di SmartCamera.gd
		camera.move_to_position(target_pos)
		await camera.move_finished # Tunggu kamera selesai gerak
	
	# Setelah kamera pindah, reset player & mulai cutscene stage 2
	player.global_position = target_pos
	start_cutscene_2() # <--- Buat fungsi baru untuk stage 2

func start_cutscene_2():
	# Poin 5: Dialog baru, lalu balapan baru
	var dialog_stage_2 = [
		{"name": "Sensei", "text": "Di sini, kamu butuh lompatan lebih...", "portrait": "sensei_serious"}
	]
	dialog_box.queue_text(dialog_stage_2)
	await dialog_box.finished
	
	# ... (lakukan logika balapan lagi, tapi di akhir berikan player.enable_double_jump()) ...

# --- Fungsi Pembantu (Pastikan ini ada di script TheStage.gd) ---
func wait_for_input(action_name: String) -> void:
	# Loop ini akan terus berjalan setiap frame...
	while not Input.is_action_just_pressed(action_name):
		# ...dan 'await' membuat script 'tertidur' 1 frame, lalu cek lagi.
		await get_tree().process_frame
