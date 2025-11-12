extends Control

# Sesuaikan dengan struktur node lu
@onready var panel = $Panel
@onready var label = $Panel/MarginContainer/VBoxContainer/Label
@onready var label2 = $Panel/MarginContainer/VBoxContainer/Label2

func _ready():
	# Set alpha jadi 0 dulu (invisible)
	modulate.a = 0
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)  # Fade in 1 detik
	tween.tween_interval(2.5)  # Tahan 2.5 detik
	tween.tween_property(self, "modulate:a", 0.0, 1.0)  # Fade out 1 detik
	tween.tween_callback(_go_to_main_menu)

func _go_to_main_menu():
	# Pakai ini kalau autoload udah setup
	#SceneManager.change_scene("res://Abscene/Mainmenu2.tscn")
	
	# ATAU pakai ini kalau belum setup autoload:
	get_tree().change_scene_to_file("res://Art/UI/UI-Scene/Mainmenu2.tscn")
