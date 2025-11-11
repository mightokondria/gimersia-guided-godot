extends AnimationPlayer
@onready var sensei: CharacterBody2D = $"../Sensei"
@onready var player: CharacterBody2D = $"../SubViewportContainer/Player"
@onready var textbox: CanvasLayer = $"../TextBox"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.set_cutscene_state(true)
	
	textbox.queue_text("Sensei", "Halo, selamat datang di latihan pertamamu.", "sensei_happy")
	textbox.queue_text("Player", "Tugasmu mudah: capai bendera di ujung sana.", "player_happy")
	textbox.queue_text("Sensei", "Hati-hati jangan sampai jatuh ya!", "sensei_happy")
	await textbox.finished
	print("Dialog selesai, lanjut ke aksi berikutnya!")
	player.set_cutscene_state(false)
	play("SenseiWalk")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
# --- Fungsi Pembantu untuk Menunggu Input ---
func wait_for_input(action_name: String) -> void:
	# Loop ini akan terus berjalan setiap frame...
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
		
