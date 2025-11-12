extends Camera2D

@export var player: CharacterBody2D
@export var follow_speed: float = 10.0
@export var max_shake: float = 140.0
@export var shake_fade: float = 10.0

# --- STAGE CONTROL ---
var stage_active := false  # dikontrol dari GameManager

# --- INTERNAL VARIABEL ---
var base_x_position: float
var base_y_position: float
var trigger_y_threshold: float  # batas 80% atas layar
var shake_strength: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var follow_enabled := true

func _ready():
	if player == null:
		push_warning("⚠ SmartCamera: player belum di-assign!")

	base_x_position = global_position.x
	base_y_position = global_position.y

	var viewport_rect = get_viewport_rect()
	var viewport_height = viewport_rect.size.y
	trigger_y_threshold = viewport_height * 0.2  # 20% bagian atas layar

	make_current()
	add_to_group("main_camera")

func _process(delta):
	if player == null:
		return

	# --- FOLLOW PLAYER ---
	if follow_enabled and stage_active:
		# ✅ Hitung posisi player di layar secara manual (tanpa world_to_screen)
		var viewport_height = get_viewport_rect().size.y
		var screen_pos_y = player.global_position.y - (global_position.y - viewport_height / 2.0)

		# Jika player melewati 80% bagian atas layar → kamera naik mengikuti
		if screen_pos_y <= trigger_y_threshold:
			var target_y = player.global_position.y - trigger_y_threshold
			global_position.y = lerp(global_position.y, target_y, follow_speed * delta)
		else:
			global_position.y = lerp(global_position.y, base_y_position, follow_speed * delta)

		# 🔒 Kunci posisi X
		global_position.x = base_x_position + shake_offset.x

	# --- CAMERA SHAKE ---
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		shake_offset = Vector2.ZERO


# ✅ Untuk aktifkan saat stage mulai
func set_stage_active(active: bool):
	stage_active = active

# ✅ Efek getaran kamera (dipanggil dari Player.gd)
func start_shake(intensity: float = 40.0, decay: float = 5.0):
	shake_strength = intensity
	shake_fade = decay

# ✅ Versi otomatis dengan timer
func trigger_shake(duration_ms: float = 300.0):
	start_shake()
	await get_tree().create_timer(duration_ms / 1000.0).timeout
	shake_strength = 0.0

# ✅ Untuk transisi/cutscene
func set_follow_enabled(active: bool):
	follow_enabled = active

# ✅ Update posisi dasar
func update_base_position():
	base_x_position = global_position.x
	base_y_position = global_position.y
