extends Node2D

# ===============================
# 🎮 NODE REFERENCES
# ===============================
@export var player: CharacterBody2D
@export var sensei: CharacterBody2D
@export var sensei_anim_player: AnimationPlayer
@export var dialog_box: CanvasLayer
@export var camera: Camera2D
@onready var skill_popup = $SkillPopup


# --- STAGE 1 ---
@export var stage1_player_spawn: Marker2D
@export var stage1_sensei_spawn: Marker2D
@export var stage1_finish_line: Area2D

# --- STAGE 2 ---
@export var stage2_player_spawn: Marker2D
@export var stage2_sensei_spawn: Marker2D
@export var stage2_finish_line: Area2D

# --- STAGE 3 ---
@export var stage3_player_spawn: Marker2D
@export var stage3_sensei_spawn: Marker2D
@export var stage3_finish_line: Area2D
@export var stage3_platform: CollisionShape2D


# ===============================
# 🧠 GAME STATE
# ===============================
var current_stage := 1
var attempt := 1
var race_in_progress := false
var player_won_race := false

var sensei_visible := true

# --- Ability unlock flags ---
var dash_unlocked := false
var double_jump_unlocked := false
var wall_grab_unlocked := false

# --- Stage configuration ---
var stages := {}

# --- Flags untuk logika finish ---
var pending_retry_dialog := false
var sensei_finished := false
var player_finished := false


# ===============================
# 🚀 READY
# ===============================
func _ready():
	print("⚙️ [READY]", name, "is inside tree?", is_inside_tree())
	
	if stage3_platform:
		stage3_platform.disabled = true  # Nonaktifkan dulu di awal


	if skill_popup:
		skill_popup.visible = false
	else:
		push_warning("⚠️ SkillPopup node tidak ditemukan!")

	# --- Setup stage configuration ---
	stages = {
		1: {
			"player_spawn": stage1_player_spawn,
			"sensei_spawn": stage1_sensei_spawn,
			"finish": stage1_finish_line,
			#"anim": "SENSEI_WALK_ST_1",
			"anim": "CUKI",
					"attempts": {
				1: {
					"intro": [["Sensei", "Selamat datang di Pelajaran Terakhir!", "sensei_happy"],
					["Sensei", "Kalahkan aku dn buat aku bangga", "sensei_happy"],
					["You", "Baik Sensei", "player_happy"]
					
					]
				},
				2: {
					"intro": [["Sensei", "Sekarang coba lagi! Kamu pasti bisa mengalahkanku!", "sensei_happy"]]
				}
			}
		},
		2: {
			"player_spawn": stage2_player_spawn,
			"sensei_spawn": stage2_sensei_spawn,
			"finish": stage2_finish_line,
			#"anim": "SENSEI_WALK_ST_2",
			"anim": "CUKI",
			"attempts": {
				1: {
					"intro": [
						["Sensei", "Selamat datang di Stage 2!", "sensei_happy"],
						["Sensei", "Di sini aku makin cepat~", "sensei_smug"]
					]
				},
				2: {
					"intro": [["Sensei", "Baik, aku akan sedikit santai. Coba kalahkan aku!", "sensei_happy"]]
				}
			}
		},
		3: {
			"player_spawn": stage3_player_spawn,
			"sensei_spawn": stage3_sensei_spawn,
			"finish": stage3_finish_line,
			#"anim": "SENSEI_WALK_ST_3",
			"anim": "CUKI",
			"attempts": {
				1: {
					"intro": [
						["Sensei", "Kamu sampai di Stage 3? Tidak buruk!", "sensei_smug"],
						["Sensei", "Tapi ini yang tersulit! Kejar aku kalau berani!", "sensei_angry"]
					]
				},
				2: {
					"intro": [["Sensei", "Aku mulai capek. Cobalah kalahkan aku!", "sensei_happy"]]
				}
			}
		}
	}

	# Hubungkan semua finish line, tapi kirim node stage-nya sebagai argumen tambahan
	for stage_id in stages.keys():
		var finish_line = stages[stage_id]["finish"]
		finish_line.body_entered.connect(_on_finish_line_entered.bind(stage_id))

	# Pindahkan ke luar loop
	await start_stage(1, 1)


# ===============================
# 💬 DIALOG HANDLER
# ===============================
func show_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		dialog_box.queue_text(d[0], d[1], d[2])
	await dialog_box.finished


# ===============================
# 🔓 ABILITY UNLOCK
# ===============================
func grant_stage_ability():
	match current_stage:
		1:
			if not dash_unlocked:
				player.enable_dash()
				skill_popup.show_skill("Skill Unlocked: DASH!" + "\n" + "Tekan [M] Untuk Dash!")
				dash_unlocked = true
		2:
			if not double_jump_unlocked:
				player.enable_double_jump()
				skill_popup.show_skill("Skill Unlocked: DOUBLE JUMP!"+ "\n" + "Tekan [SPACE 2x] Untuk Double Jump!")
				double_jump_unlocked = true
		3:
			if not wall_grab_unlocked:
				player.enable_wall_grab()
				skill_popup.show_skill("Skill Unlocked: WALL GRAB!")
				wall_grab_unlocked = true


# ===============================
# 🏁 START STAGE
# ===============================
func start_stage(stage_num: int, attempt_num: int):
	
	current_stage = stage_num
	attempt = attempt_num
	race_in_progress = false

	# Reset flags finish
	pending_retry_dialog = false
	sensei_finished = false
	player_finished = false

	var attempt_data = stages[current_stage]["attempts"][attempt]
	player.set_cutscene_state(true)
	sensei_anim_player.stop()

	await show_dialogs(attempt_data["intro"])

	var p_spawn = stages[current_stage]["player_spawn"]
	var s_spawn = stages[current_stage]["sensei_spawn"]

	if p_spawn and s_spawn:
		player.global_position = p_spawn.global_position
		sensei.global_position = s_spawn.global_position
		restore_sensei()
	else:
		push_warning("⚠️ Spawn point tidak ditemukan untuk stage " + str(current_stage))

	# ✅ Aktifkan barrier hanya saat Stage 3
	if stage3_platform:
		stage3_platform.disabled = (stage_num != 3)
		print("AW")
	else:
		stage3_platform.disabled = (stage_num == 3)
		print("aku gila")
	
	# mainkan animasi Sensei sesuai stage
	var anim = stages[current_stage]["anim"]
	if sensei_anim_player and sensei_anim_player.has_animation(anim):
		sensei_anim_player.play(anim)
	else:
		sensei_anim_player.stop()

	player.set_cutscene_state(false)
	
	if camera and camera.has_method("set_stage_active"):
		camera.set_stage_active(true)

		

	race_in_progress = true


# ===============================
# 🏁 FINISH LINE HANDLER
# ===============================
func _on_finish_line_entered(body: Node, stage_id: int):
	if not race_in_progress:
		return

	# --- Abaikan garis finish dari stage lain ---
	if stage_id != current_stage:
		return

	# --- Lanjutkan logika seperti biasa ---
	if body.name == "Player":
		player_won_race = true
	elif body.name == "Sensei":
		player_won_race = false
	else:
		return

	race_in_progress = false
	sensei_anim_player.stop()
	_evaluate_race_result()




# ===============================
# 🏆 EVALUATE RACE RESULT
# ===============================
func _evaluate_race_result():
	player.set_cutscene_state(true)
	race_in_progress = false
	pending_retry_dialog = false

	if player_won_race:
		grant_stage_ability()
		await show_dialogs([["Sensei", "Bagus! Kamu menang!", "sensei_happy"]])

		if current_stage < 3:
			await move_camera_to_stage(current_stage + 1)
		else:
			await show_dialogs([
				["Sensei", "Tidak mungkin... kamu mengalahkanku!", "sensei_shock"],
				["Sensei", "Kamu pemenang sejati!", "sensei_happy"]
			])
			get_tree().change_scene_to_file("res://Art/UI/UI-Scene/Mainmenu2.tscn")
		return

	# --- KALAH (setelah player juga sampai finish) ---
	await show_dialogs([
		["Sensei", "Masih kurang cepat! Ulangi lagi!", "sensei_angry"]
	])

	await wait_for_input("ui_accept")
	grant_stage_ability()

	attempt = 2
	await start_stage(current_stage, attempt)


# ===============================
# 🎥 CAMERA TRANSITION
# ===============================
func move_camera_to_stage(stage_num: int):
	camera.set_follow_enabled(false)
	camera.set_stage_active(false)
	
	# 🧭 Deklarasikan variabel sebelum digunakan
	var target_offset := Vector2.ZERO
	var target := Vector2.ZERO
	
	match stage_num:
		2:
			# Stage 1 → Stage 2: geser kanan 2355px
			target_offset = Vector2(2355, 0)
		3:
			# Stage 2 → Stage 3: naik 1080px
			target_offset = Vector2(0, -930)
		_:
			# Default: tidak bergeser
			target_offset = Vector2.ZERO

	target = camera.global_position + target_offset
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	camera.update_base_position()
	camera.set_follow_enabled(true)

	await start_stage(stage_num, 1)
	
func fade_out_sensei():
	if sensei:
		sensei.visible = false
		sensei_visible = false
		
func restore_sensei():
	if sensei:
		sensei.visible = true
		sensei.modulate.a = 1.0
		sensei_visible = true



# ===============================
# ⏳ WAIT INPUT
# ===============================
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
