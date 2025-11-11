extends Node2D

# --- Referensi Node ---
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
var current_stage := 1
var stage_1_attempt := 1
var player_won_race := false
var race_in_progress := false

# --- Konfigurasi Data Stage (mudah dikembangkan) ---
var stages := {}

func _ready():
	info.visible = false
	
	stages = {
		1: {
			"spawn": stage1_spawn,
			"finish": stage1_finish_line,
			"attempts": {
				1: {
					"intro_dialog": [
						["Sensei", "Perhatikan aku baik-baik. Kejar jika bisa!", "sensei_happy"]
					],
					"sensei_speed": "fast",
					"can_win": false
				},
				2: {
					"intro_dialog": [
						["Sensei", "Sekarang, coba lagi! Kalahkan aku!", "player_happy"]
					],
					"sensei_speed": "slow",
					"can_win": true
				}
			}
		},
		2: {
			"spawn": stage2_spawn,
			"intro_dialog": [
				["Sensei", "Selamat datang di Stage 2. Tantangannya beda lagi!", "sensei_happy"]
			]
		}
	}
	
	stage1_finish_line.body_entered.connect(_on_finish_line_entered)
	reset_positions()
	start_stage(1, 1)

# --- UTILITY FUNGI ---
func reset_positions():
	var spawn = stages[current_stage]["spawn"]
	player.global_position = spawn.global_position
	sensei.global_position = spawn.global_position

func show_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		dialog_box.queue_text(d[0], d[1], d[2])
	await dialog_box.finished

func start_stage(stage_num: int, attempt_num: int = 1):
	current_stage = stage_num
	stage_1_attempt = attempt_num
	
	match stage_num:
		1:
			await start_race(attempt_num)
		2:
			await start_stage_2()

# --- LOGIKA BALAPAN UMUM ---
func start_race(attempt_num: int):
	player.set_cutscene_state(true)
	sensei_anim_player.stop()
	
	var attempt_data = stages[1]["attempts"][attempt_num]
	await show_dialogs(attempt_data["intro_dialog"])
	
	reset_positions()
	
	race_in_progress = true
	sensei_anim_player.play("SenseiWalk_2") # misalnya anim: SenseiWalk_fast/slow
	player.set_cutscene_state(false)

# --- DETEKSI FINISH LINE ---
func _on_finish_line_entered(body):
	if not race_in_progress:
		return

	if body.name == "Player":
		player_won_race = true
	elif body.name == "Sensei":
		player_won_race = false
	else:
		return

	race_in_progress = false
	sensei_anim_player.stop()
	_evaluate_race_result()

# --- EVALUASI HASIL BALAPAN ---
func _evaluate_race_result():
	player.set_cutscene_state(true)

	if player_won_race:
		await show_dialogs([["Sensei", "Bagus! Kamu berhasil!", "sensei_happy"]])
		move_camera_to_stage(2)
		return
	
	# Kalau kalah:
	match stage_1_attempt:
		1:
			await show_dialogs([
				["Sensei", "PAYAH! Aku terlalu cepat untukmu.", "player_happy"],
				["Sensei", "Coba pakai ini. Tekan [M] untuk meluncur!", "sensei_happy"]
			])
			player.enable_dash()
			
			info.visible = true
			await get_tree().process_frame
			await wait_for_input("ui_accept")
			info.visible = false
			
			stage_1_attempt = 2
			await start_race(stage_1_attempt)
			
		2:
			await show_dialogs([
				["Sensei", "Masih terlalu lambat! Gunakan Dash-mu lebih baik!", "sensei_happy"],
				["Sensei", "Kita ulangi!", "player_happy"]
			])
			await start_race(stage_1_attempt)

# --- TRANSISI STAGE ---
func move_camera_to_stage(stage_num: int):
	print("KAMERA BERGESER KE STAGE ", stage_num)
	await start_stage(stage_num)

# --- STAGE 2 ---
func start_stage_2():
	await show_dialogs(stages[2]["intro_dialog"])
	# Tambah logika Stage 2 (misalnya sensei lebih cepat, player dapat double jump)
	player.enable_double_jump()

# --- HELPER ---
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
