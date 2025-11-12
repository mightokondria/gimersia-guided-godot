extends Camera2D

@export var player: CharacterBody2D
@export var follow_speed: float = 10.0
@export var max_shake: float = 140.0
@export var shake_fade: float = 10.0

var base_x_position: float
var base_y_position: float
var trigger_y_local: float
var shake_strength: float = 0.0
var follow_enabled := true
var shake_offset: Vector2 = Vector2.ZERO

func _ready():
	if player == null:
		push_warning("⚠ SmartCamera: player belum di-assign!")

	base_x_position = global_position.x
	base_y_position = global_position.y

	var viewport_rect = get_viewport_rect()
	var viewport_height = viewport_rect.size.y
	var half_height = viewport_height / 2.0
	var trigger_percentage = 0.2
	trigger_y_local = -half_height + (viewport_height * trigger_percentage)

	make_current()  # Pastikan kamera aktif
	add_to_group("main_camera")

func _process(delta):
	if player == null:
		return

	# --- FOLLOW PLAYER ---
	if follow_enabled:
		var player_local_y = player.global_position.y - global_position.y
		var target_y := base_y_position
		if player_local_y < trigger_y_local:
			target_y = player.global_position.y - trigger_y_local

		# Tambahkan efek getar ke posisi kamera
		global_position.x = base_x_position + shake_offset.x
		global_position.y = lerp(global_position.y, target_y, follow_speed * delta) + shake_offset.y

	# --- CAMERA SHAKE ---
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		shake_offset = Vector2.ZERO


# ✅ Panggil dari luar: camera.start_shake(40.0, 5.0)
func start_shake(intensity: float = 40.0, decay: float = 5.0):
	shake_strength = intensity
	shake_fade = decay

# ✅ Versi dengan timer: camera.trigger_shake()
func trigger_shake(duration_ms: float = 300.0):
	start_shake()
	await get_tree().create_timer(duration_ms / 1000.0).timeout
	shake_strength = 0.0

# ✅ Untuk transisi / cutscene
func set_follow_enabled(active: bool):
	follow_enabled = active

# ✅ Update base posisi kamera (biasanya setelah tween)
func update_base_position():
	base_x_position = global_position.x
	base_y_position = global_position.y
