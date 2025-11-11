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
var attempt := 1
var race_in_progress := false
var player_won_race := false

# --- STAGE DATA CONFIG ---
var stages := {}

func _ready():
	info.visible = false

	stages = {
		1: {
			"spawn": stage1_spawn,
			"finish": stage1_finish_line,
			"anim": "SenseiWalk_2",
			"attempts": {
				1: {
					"intro": [
						["Sensei", "Perhatikan aku baik-baik. Kejar jika bisa!", "sensei_happy"]
					],
					"unlock_skill": null
				},
				2: {
					"intro": [
						["Sensei", "Sekarang coba lagi! Kamu pasti bisa mengalahkanku!", "sensei_happy"]
					],
					"unlock_skill": "dash"
				}
			}
		},

		2: {
			"spawn": stage2_spawn,
			"finish": stage2_finish_line,
			"anim": "SenseiWalk_3",
			"attempts": {
				1: {
					"intro": [
						["Sensei", "Selamat datang di Stage 2!", "sensei_happy"],
						["Sensei", "Di sini aku makin cepat~", "sensei_smug"]
					],
					"unlock_skill": null
				},
				2: {
					"intro": [
						["Sensei", "Baik, aku akan sedikit santai. Coba kalahkan aku!", "sensei_happy"]
					],
					"unlock_skill": "double_jump"
				}
			}
		},

		3: {
			"spawn": stage3_spawn,
			"finish": stage3_finish_line,
			"anim": "SenseiWalk_4",
			"attempts": {
				1: {
					"intro": [
						["Sensei", "Kamu sampai di Stage 3? Tidak buruk!", "sensei_smug"],
						["Sensei", "Tapi ini yang tersulit! Kejar aku kalau berani!", "sensei_angry"]
					],
					"unlock_skill": null
				},
				2: {
					"intro": [
						["Sensei", "Aku mulai capek. Coba kalahkan aku!", "sensei_happy"]
					],
					"unlock_skill": "wall_grab"
				}
			}
		}
	}

	# Hubungkan semua finish line otomatis
	for s in stages.values():
		s["finish"].body_entered.connect(_on_finish_line_entered)

	start_stage(1, 1)


# --- DIALOG ---
func show_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		dialog_box.queue_text(d[0], d[1], d[2])
	await dialog_box.finished


# --- START ANY STAGE & ATTEMPT ---
func start_stage(stage_num: int, attempt_num: int):
	current_stage = stage_num
	attempt = attempt_num

	var attempt_data = stages[current_stage]["attempts"][attempt]

	player.set_cutscene_state(true)
	sensei_anim_player.stop()

	# --- dialog pembuka ---
	await show_dialogs(attempt_data["intro"])

	# --- reset player saja (sensei sudah otomatis pindah lewat animasi) ---
	var spawn = stages[current_stage]["spawn"]
	player.global_position = spawn.global_position + Vector2(100, 0)

	# mulai race
	race_in_progress = true

	# ✅ animasi sensei sesuai stage
	var anim = stages[current_stage]["anim"]
	print("Playing anim:", anim, "on Stage:", current_stage)
	sensei_anim_player.play(anim)

	player.set_cutscene_state(false)


# --- FINISH DETECT ---
func _on_finish_line_entered(body):
	if not race_in_progress:
		return

	player_won_race = (body.name == "Player")
	race_in_progress = false
	sensei_anim_player.stop()

	_evaluate_race_result()


# --- RESULT ---
func _evaluate_race_result():
	player.set_cutscene_state(true)

	if player_won_race:
		await show_dialogs([["Sensei", "Bagus! Kamu menang!", "sensei_happy"]])

		if current_stage < 3:
			move_camera_to_stage(current_stage + 1)
		else:
			await show_dialogs([
				["Sensei", "Tidak mungkin... kamu mengalahkanku!", "sensei_shock"],
				["Sensei", "Kamu pemenang sejati!", "sensei_happy"]
			])
		return

	# ---- KALAH ----
	await show_dialogs([["Sensei", "Masih kurang cepat! Ulang lagi!", "sensei_angry"]])

	var unlock = stages[current_stage]["attempts"][attempt]["unlock_skill"]

	# kalah attempt pertama → unlock skill
	if unlock != null:
		match unlock:
			"dash": player.enable_dash()
			"double_jump": player.enable_double_jump()
			"wall_grab": player.enable_wall_grab()

		await show_dialogs([
			["Sensei", "Aku bantu sedikit... aku kasih skill baru!", "sensei_happy"]
		])

		info.visible = true
		await wait_for_input("ui_accept")
		info.visible = false

		attempt = 2
		await start_stage(current_stage, attempt)
	else:
		await start_stage(current_stage, attempt)


# --- CAMERA ---
func move_camera_to_stage(stage_num: int):
	camera.set_follow_enabled(false)

	var target = camera.global_position + Vector2(1920, 0)
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	camera.update_base_position()
	camera.set_follow_enabled(true)

	await start_stage(stage_num, 1)


# --- WAIT INPUT ---
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
