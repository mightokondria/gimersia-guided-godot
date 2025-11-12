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

# ===============================
# 🧩 GAME STATE
# ===============================
var current_stage := 1
var attempt := 1
var race_in_progress := false
var player_won_race := false

# --- Ability unlock flags ---
var dash_unlocked := false
var double_jump_unlocked := false
var wall_grab_unlocked := false

# --- Stage configuration ---
var stages := {}

# ===============================
# 🚀 READY
# ===============================
func _ready():
	print("⚙️ [READY]", name, "is inside tree?", is_inside_tree())

	if skill_popup:
		skill_popup.visible = false
	else:
		push_warning("⚠️ SkillPopup node tidak ditemukan!")

	# Setup stage configuration
	stages = {
		1: {
			"player_spawn": stage1_player_spawn,
			"sensei_spawn": stage1_sensei_spawn,
			"finish": stage1_finish_line,
			"anim": "SENSEI_WALK_ST_1",
			"attempts": {
				1: { "intro": [["Sensei", "Perhatikan aku baik-baik. Kejar jika bisa!", "sensei_happy"]] },
				2: { "intro": [["Sensei", "Sekarang coba lagi! Kamu pasti bisa mengalahkanku!", "sensei_happy"]] }
			}
		},
		2: {
			"player_spawn": stage2_player_spawn,
			"sensei_spawn": stage2_sensei_spawn,
			"finish": stage2_finish_line,
			"anim": "SenseiWalk_3",
			"attempts": {
				1: { "intro": [["Sensei", "Selamat datang di Stage 2!", "sensei_happy"], ["Sensei", "Di sini aku makin cepat~", "sensei_smug"]] },
				2: { "intro": [["Sensei", "Baik, aku akan sedikit santai. Coba kalahkan aku!", "sensei_happy"]] }
			}
		},
		3: {
			"player_spawn": stage3_player_spawn,
			"sensei_spawn": stage3_sensei_spawn,
			"finish": stage3_finish_line,
			"anim": "SenseiWalk_4",
			"attempts": {
				1: { "intro": [["Sensei", "Kamu sampai di Stage 3? Tidak buruk!", "sensei_smug"], ["Sensei", "Tapi ini yang tersulit! Kejar aku kalau berani!", "sensei_angry"]] },
				2: { "intro": [["Sensei", "Aku mulai capek. Cobalah kalahkan aku!", "sensei_happy"]] }
			}
		}
	}

	# Connect all finish lines
	for s in stages.values():
		if s["finish"]:
			s["finish"].body_entered.connect(_on_finish_line_entered)
		else:
			push_warning("⚠️ Finish line belum diassign untuk salah satu stage.")

	# Mulai dari Stage 1
	await start_stage(1, 1)


# ===============================
# 💬 DIALOG SYSTEM
# ===============================
func show_dialogs(dialogs: Array) -> void:
	for d in dialogs:
		dialog_box.queue_text(d[0], d[1], d[2])
	await dialog_box.finished


# ===============================
# 🔓 ABILITY UNLOCK LOGIC
# ===============================
func grant_stage_ability():
	match current_stage:
		1:
			if not dash_unlocked:
				player.enable_dash()
				skill_popup.show_skill("Skill Unlocked: DASH!")
				dash_unlocked = true
		2:
			if not double_jump_unlocked:
				player.enable_double_jump()
				skill_popup.show_skill("Skill Unlocked: DOUBLE JUMP!")
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

	var attempt_data = stages[current_stage]["attempts"][attempt]
	player.set_cutscene_state(true)
	sensei_anim_player.stop()

	await show_dialogs(attempt_data["intro"])

	# Spawn posisi terpisah
	var p_spawn = stages[current_stage]["player_spawn"]
	var s_spawn = stages[current_stage]["sensei_spawn"]

	if p_spawn and s_spawn:
		player.global_position = p_spawn.global_position
		sensei.global_position = s_spawn.global_position
	else:
		push_warning("⚠️ Spawn point tidak ditemukan untuk stage " + str(current_stage))

	# Mainkan animasi Sensei sesuai stage
	var anim = stages[current_stage]["anim"]
	if sensei_anim_player.has_animation(anim):
		sensei_anim_player.play(anim)
	else:
		push_warning("⚠️ Animasi '" + anim + "' tidak ditemukan di Sensei.")

	player.set_cutscene_state(false)
	race_in_progress = true


# ===============================
# 🏁 FINISH LINE HANDLER
# ===============================
func _on_finish_line_entered(body):
	if not race_in_progress:
		return

	player_won_race = (body.name == "Player")
	race_in_progress = false
	sensei_anim_player.stop()

	_evaluate_race_result()


# ===============================
# 🏆 EVALUATE RACE RESULT
# ===============================
func _evaluate_race_result():
	player.set_cutscene_state(true)

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
		return

	# Kalau kalah
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

	var target = camera.global_position + Vector2(1920, 0)
	var tween = create_tween()
	tween.tween_property(camera, "global_position", target, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	camera.update_base_position()
	camera.set_follow_enabled(true)

	await start_stage(stage_num, 1)


# ===============================
# ⏳ WAIT INPUT
# ===============================
func wait_for_input(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame


# ===============================
# 🧰 SAFE ADD CHILD (UTILITY)
# ===============================
func safe_add_child(parent: Node, child: Node):
	if parent == null or child == null:
		push_warning("⚠️ safe_add_child: Salah satu node null!")
		return
	if not is_instance_valid(parent):
		push_warning("⚠️ Parent tidak valid!")
		return
	parent.add_child(child)
