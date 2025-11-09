extends Camera2D

@export var player: Node2D
@export var follow_speed: float = 5.0

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
