extends Control

@onready var game_logo = $CenterContainer/VBoxContainer/GameLogo
@onready var loading_bar = $CenterContainer/VBoxContainer/LoadingBar
@onready var press_any_key = $CenterContainer/VBoxContainer/PressAnyKey

var loading_progress = 0.0
var loading_complete = false

func _ready():
	# Hide press any key text
	press_any_key.visible = false
	 
	# Fade in game logo
	game_logo.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(game_logo, "modulate:a", 1.0, 1.0)
	
	# Start loading animation
	_start_loading()

func _start_loading():
	# Simulasi loading (bisa diganti dengan actual resource loading)
	var tween = create_tween()
	tween.tween_property(self, "loading_progress", 100.0, 2.0)
	tween.tween_callback(_on_loading_complete)

func _process(_delta):
	# Update loading bar
	loading_bar.value = loading_progress

func _on_loading_complete():
	loading_complete = true
	
	# Hide loading bar
	var tween = create_tween()
	tween.tween_property(loading_bar, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		loading_bar.visible = false
		_show_press_any_key()
	)

func _show_press_any_key():
	press_any_key.visible = true
	press_any_key.modulate.a = 0
	
	# Animasi blinking "Press Any Key"
	var tween = create_tween().set_loops()
	tween.tween_property(press_any_key, "modulate:a", 1.0, 0.7)
	tween.tween_property(press_any_key, "modulate:a", 0.3, 0.7)

func _input(event):
	if !loading_complete:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_go_to_main_menu()



func _go_to_main_menu():
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://UI/UI-Scene/Mainmenu2.tscn")
	)
