extends Node2D

# --- NODE REFERENCES ---
@export var player: CharacterBody2D
@export var sensei: CharacterBody2D
@export var sensei_anim_player: AnimationPlayer
@export var dialog_box: CanvasLayer
@export var camera: Camera2D

@export var stage1_spawn: Marker2D
@export var stage1_finish_line: Area2D
@export var stage2_spawn: Marker2D
@export var stage2_finish_line: Area2D
@export var stage3_spawn: Marker2D
@export var stage3_finish_line: Area2D

@onready var info: CanvasLayer = $Info

# --- GAME STATE ---
var current_stage := 1
var player_attempt := 1
var player_won_race := false
var race_in_progress := false

# --- STAGE DATA ---
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
						["Sensei", "Sekarang, coba lagi! Kamu pasti bisa mengalahkanku!", "sensei_happy"]
					],
					"sensei_speed": "slow",
					"can_win": true
				}
			}
		},

		2: {
			"spawn": stage2_spawn,
			"finish": stage2_finish_line,
			"attempts": {
				1: {
					"intro_dialog": [
						["Sensei", "Selamat datang di Stage 2!", "sensei_happy"],
						["Sensei", "Di sini aku lebih cepat lagi!", "sensei_smug"]
					],
					"sensei_speed": "fast",
					"can_win": false
				},
				2: {
					"intro_dialog": [
						["Sensei", "Baik, aku akan sedikit santai. Coba kalahkan aku!", "sensei_happy"]
					],
					"sensei_speed": "slow",
					"can_win": true
				}
			}
		},

		3: {
			"spawn": stage3_spawn,
			"finish": stage3_finish_line,
			"attempts": {
				1: {
					"intro_dialog": [
						["Sensei", "Kau sampai di Stage 3... tidak buruk!", "sensei_smug"],
						["Sensei", "Tapi ini yang paling sulit! Kejar aku kalau berani!", "sensei_angry"]
					],
					"sensei_speed": "fast",
					"can_win": false
				},
				2: {
					"intro_dialog": [
						["Sensei", "Oke... aku mulai capek. Cobalah kalahkan aku!", "sensei_happy"]
					],
					"sensei_speed": "slow",
					"can_win": true
				}
			}
		}
	}

	# Hubungkan semua finish line otomatis
	for s in stages.values():
		s["finish"].body_entered.connect(_on_finish_line_entered)

	reset_positions()
	start_stage(1, 1)

# --- RESET POSISI ---
func reset_positions():
	var spawn = stages[current_stage]["spawn"]
	player.global_position = spawn.global_position
	sensei.global_position = spawn.global_position + Vector2(-100, 0)

# --- SHOW DIALOG QUEUE ---
func show_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		dialog_box.queue_text(d[0], d[1], d[2])
	await dialog_box.finished

# --- MULAI STAGE ---
func start_stage(stage_num: int, attempt_num: int = 1):
	current_stage = stage_num
	player_attempt = attempt_num

	var attempt_data = stages[stage_num]["attempts"][attempt_num]

	player.set_cutscene_state(true)
	sensei_anim_player.stop()

	await show_dialogs(attempt_data["intro_dialog"])
	reset_positions()

	# Mulai balapan
	race_in_progress = true
	sensei_anim_player.play("SenseiWalk_2")

	player.set_cutscene_state(false)

# --- DETEKSI FINISH LINE ---
func _on_finish_line_entered(body):
	if not race_in_progress:
		return

	player_won_race = (body.name == "Player")
	race_in_progress = false
	sensei_anim_player.stop()

	_evaluate_race_result()

# --- HASIL BALAPAN ---
func _evaluate_race_result():
	player.set_cutscene_state(true)

	if player_won_race:
		await show_dialogs([["Sensei", "Bagus! Kamu menang!", "sensei_happy"]])

		if current_stage < 3:
			move_camera_to_stage(current_stage + 1)
		else:
			await show_dialogs([
				["Sensei", "Tidak mungkin... kau sudah mengalahkanku!", "sensei_shock"],
				["Sensei", "Kamu pemenang sejati!", "sensei_happy"]
			])
		return

	# KALAH
	await show_dialogs([
		["Sensei", "Haha! Masih kurang cepat!", "sensei_smug"]
	])

	if player_attempt == 1:
		await show_dialogs([
			["Sensei", "Baiklah... aku kasih kamu skill baru!", "sensei_happy"]
		])

		if current_stage == 1:
			player.enable_dash()
		elif current_stage == 2:
			player.enable_double_jump()
		elif current_stage == 3:
			player.enable_wall_grab()

		info.visible = true
		await get_tree().process_frame
		await wait_for_input("ui_accept")
		info.visible = false

		player_attempt = 2
		await start_stage(current_stage, player_attempt)
	else:
		await show_dialogs([
			["Sensei", "Masih kalah? Coba lagi!", "sensei_angry"]
		])
		await start_stage(current_stage, player_attempt)

# --- PINDAH KAMERA ---
func move_camera_to_stage(stage_num: int):
	camera.set_follow_enabled(false)

	var target = camera.global_position + Vector2(1920, 0)
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	camera.update_base_position()
	camera.set_follow_enabled(true)

	# Reposition player & sensei
	current_stage = stage_num
	var spawn = stages[stage_num]["spawn"]
	var finish = stages[stage_num]["finish"]

	player.global_position = spawn.global_position + Vector2(100, 0)
	sensei.global_position = finish.global_position

	await start_stage(stage_num)

# --- HELPER ---
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
