extends AnimationPlayer
@onready var sensei: CharacterBody2D = $"../Sensei"
@onready var player: CharacterBody2D = $"../SubViewportContainer/Player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.set_cutscene_state(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
# --- Fungsi Pembantu untuk Menunggu Input ---
func wait_for_input(action_name: String) -> void:
	# Loop ini akan terus berjalan setiap frame...
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
		
