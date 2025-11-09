extends Camera2D

@export var player: Node2D
@export var follow_speed: float = 10.0

@export var max_shake: float = 4.0
@export var shake_fade: float = 0.0

var _shake_strength: float = 0.0



var base_y_position: float
var base_x_position: float # <--- TAMBAHAN BARU
var trigger_y_local: float

func _ready():
	if player == null:
		print("ERROR KAMERA: Node 'Player' belum di-assign!")
	
	# Simpan posisi awal kamera di editor sebagai "posisi dasar"
	base_y_position = global_position.y
	base_x_position = global_position.x # <--- TAMBAHAN BARU
	
	var viewport_rect = get_viewport_rect()
	var viewport_height = viewport_rect.size.y
	var half_height = viewport_height / 2.0
	var trigger_zone_percentage = 0.20 
	trigger_y_local = -half_height + (viewport_height * trigger_zone_percentage)

func _process(delta):
	if player == null: return

	var player_local_y = player.global_position.y - global_position.y
	var target_y: float
	
	if player_local_y < trigger_y_local:
		target_y = player.global_position.y - trigger_y_local
	else:
		target_y = base_y_position
		
	global_position.y = lerp(global_position.y, target_y, follow_speed * delta)
	
	# Kunci posisi X ke posisi dasar yang baru
	global_position.x = base_x_position # <--- UBAH BARIS INI
	
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		if _shake_strength < 0.1:
			_shake_strength = 0.0
			offset = Vector2.ZERO # Pastikan offset kembali ke (0,0)
		else:
			offset = Vector2(randf_range(-_shake_strength, _shake_strength),randf_range(-_shake_strength, _shake_strength))

func trigger_shake(duration_ms: float = 300.0) -> void:
	# 1. Set kekuatan getaran ke maksimal (logika Anda)
	_shake_strength = max_shake
	
	# 2. Tunggu selama durasi yang diinginkan (misal: 0.3 detik)
	await get_tree().create_timer(duration_ms / 1000.0).timeout
	
	# 3. Setelah waktu habis, PAKSA berhenti dengan meng-nol-kan kekuatannya
	_shake_strength = 0.0
	
	
	
	
#func _process(delta: float) -> void:
	#if _shake_strength > 0:
			#_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
			#offset = Vector2(randf_range(-_shake_strength, _shake_strength),randf_range(-_shake_strength, _shake_strength))
	
	
	
	
	
