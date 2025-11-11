extends Node2D

# --- Referensi Node (Isi di Inspector) ---
@export var player: CharacterBody2D
@export var sensei: CharacterBody2D
@export var sensei_anim_player: AnimationPlayer
@export var dialog_box: CanvasLayer
@export var camera: Camera2D
@export var stage1_spawn: Marker2D
@export var stage1_finish_line: Area2D
@export var stage2_spawn: Marker2D
@onready var info: CanvasLayer = $Info

# --- Variabel Status Game ---
var current_stage = 1
var stage_1_attempt = 1 # 1 = Percobaan pertama, 2 = Percobaan kedua (dgn Dash)
var player_won_race = false
var race_in_progress = false

func _ready():
	info.visible = false
	stage1_finish_line.body_entered.connect(_on_finish_line_entered)
	# Reset posisi
	player.global_position = stage1_spawn.global_position
	sensei.global_position = stage1_spawn.global_position
	
	# Mulai alur game dengan percobaan pertama
	start_stage_1_attempt_1()

# --- TAHAP 1: PERCOBAAN PERTAMA (PASTI KALAH) ---
func start_stage_1_attempt_1():
	# Matikan kontrol player
	player.set_cutscene_state(true)
	
	
	
	# Dialog awal
	dialog_box.queue_text("Sensei", "Perhatikan aku baik-baik. Kejar jika bisa!", "sensei_happy")
	await dialog_box.finished
	
	# Poin 1: Mulai balapan pertama (Sensei cepat, tidak bisa dikalahkan)
	race_in_progress = true
	sensei_anim_player.play("SenseiWalk") # <--- Animasi SENSEI CEPAT
	player.set_cutscene_state(false) # Player boleh main
	
	#... Kita tunggu player/sensei menyentuh garis finis ...
	#... Sensei PASTI akan menang ...

# --- TAHAP 2: PERCOBAAN KEDUA (SETELAH DAPAT DASH) ---
func start_stage_1_attempt_2():
	# Reset posisi
	player.global_position = stage1_spawn.global_position
	sensei.global_position = stage1_spawn.global_position

	# Dialog sebelum balapan ulang
	dialog_box.queue_text("Sensei", "Sekarang, coba lagi! Kalahkan aku!", "player_happy")
	await dialog_box.finished
	
	# Poin 3: Mulai balapan kedua (Sensei lebih lambat, bisa dikalahkan)
	race_in_progress = true
	sensei_anim_player.play("SenseiWalk") # <--- Animasi SENSEI LEBIH LAMBAT
	player.set_cutscene_state(false) # Player boleh main

# --- FUNGSI DETEKSI GARIS FINIS ---
func _on_finish_line_entered(body):
	if not race_in_progress:
		return
		
	if body.name == "Player":
		# Player menang
		player_won_race = true
		race_in_progress = false
		sensei_anim_player.stop() # Hentikan Sensei
		_evaluate_race_result()
		
	elif body.name == "Sensei":
		# Sensei menang
		player_won_race = false
		race_in_progress = false
		player.set_cutscene_state(true) # Kunci Player
		_evaluate_race_result()

# --- FUNGSI EVALUASI HASIL BALAPAN ---
func _evaluate_race_result():
	# Matikan kontrol player sementara
	player.set_cutscene_state(true)

	if player_won_race:
		# Poin 4: PLAYER MENANG
		dialog_box.queue_text("Sensei", "Bagus! Kamu berhasil!", "sensei_happy")
		await dialog_box.finished
		
		# Poin 5: Pindah ke stage 2
		move_camera_to_stage(2)
		
	else:
		# PLAYER KALAH
		if stage_1_attempt == 1:
			# Poin 2: Kalah di percobaan PERTAMA -> Dapat Dash
			dialog_box.queue_text("Sensei", "PAYAH! Aku terlalu cepat untukmu.", "player_happy")
			dialog_box.queue_text("Sensei", "Coba pakai ini. Tekan [M] untuk meluncur!", "sensei_happy")
			await dialog_box.finished
			
			player.enable_dash() # Berikan ability
			
			# Tampilkan info bar "Tekan Spasi untuk lanjut"
			info.visible = true
			await get_tree().process_frame # Tunggu 1 frame agar info muncul
			await wait_for_input("ui_accept")
			info.visible = false
			
			# Ubah status percobaan & mulai balapan lagi
			stage_1_attempt = 2
			start_stage_1_attempt_2()
			
		else:
			# Poin 4 (Loop): Kalah lagi di percobaan KEDUA -> Ulangi
			dialog_box.queue_text("Sensei", "Masih terlalu lambat! Gunakan Dash-mu lebih baik!", "sensei_happy")
			dialog_box.queue_text("Sensei", "Kita ulangi!", "player_happy")
			await dialog_box.finished
			
			# Mulai balapan ulang (percobaan kedua lagi)
			start_stage_1_attempt_2()

# --- Poin 5: Pindah Stage & Kamera ---
func move_camera_to_stage(stage_num):
	if stage_num == 2:
		# Ini adalah placeholder yang Anda minta
		print("KAMERA BERGESER KE STAGE 2")
		
		# (Nanti, kode asli akan memindahkan kamera,
		# menunggu kamera sampai, lalu memanggil start_stage_2())
		
		# Kita panggil saja langsung untuk tes
		start_stage_2()

func start_stage_2():
	# Poin 5: Dialog baru, lalu balapan baru
	dialog_box.queue_text("Sensei", "Selamat datang di Stage 2. Tantangannya beda lagi!", "sensei_happy")
	await dialog_box.finished
	
	# ... (lakukan logika balapan lagi, tapi di akhir berikan player.enable_double_jump()) ...

# --- Fungsi Pembantu (Sangat Penting) ---
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
