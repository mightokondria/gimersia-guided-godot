# ==============================================
# SCRIPT 1: PauseManager.gd
# Attach ke: Node ROOT (Control) dari scene game Anda
# ==============================================
extends Control

@onready var pause_button = $PauseButton
@onready var pause_menu = $PauseMenu
@onready var game_ui = $GameUI

var sfx_volume: float = 1.0
var music_volume: float = 1.0

func _ready():
	# Pastikan PauseMenu dan child-nya punya Process Mode: Always
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initial state: pause menu hidden, game UI visible
	pause_menu.visible = false
	pause_button.visible = true
	game_ui.visible = true
	
	# Connect button signalsd
	pause_button.pressed.connect(_on_pause_button_pressed)
	pause_menu.get_node("Panel2/VBoxContainer/VBoxContainer/MarginContainer/VBoxContainer/Resume").pressed.connect(_on_resume_pressed)
	pause_menu.get_node("Panel2/VBoxContainer/VBoxContainer/MarginContainer/VBoxContainer/Restart").pressed.connect(_on_restart_pressed)
	pause_menu.get_node("Panel2/VBoxContainer/VBoxContainer/MainMenu").pressed.connect(_on_main_menu_pressed)
	
	# Connect sliders
	pause_menu.get_node("Panel2/VBoxContainer/MarginContainer/VBoxContainer2/HBoxContainer2/HSlider").value_changed.connect(_on_sfx_changed)
	pause_menu.get_node("Panel2/VBoxContainer/MarginContainer/VBoxContainer2/HBoxContainer3/HSlider").value_changed.connect(_on_music_changed)

# ========== PAUSE FUNCTIONS ==========
func _on_pause_button_pressed():
	pause_game()


func pause_game():
	# Pause the game tree
	get_tree().paused = true
	
	# Show pause menu, hide pause button and game UI
	pause_menu.visible = true
	pause_button.visible = false
	game_ui.visible = false
	
	print("Game Paused")

# ========== RESUME BUTTON ==========
func _on_resume_pressed():
	resume_game()

func resume_game():
	# Unpause the game tree
	get_tree().paused = false
	
	# Hide pause menu, show pause button and game UI back
	pause_menu.visible = false
	pause_button.visible = true
	game_ui.visible = true
	
	print("Game Resumed")

# ========== RESTART BUTTON ==========
func _on_restart_pressed():
	# Unpause sebelum restart
	get_tree().paused = false
	
	# Reload scene dari awal
	get_tree().reload_current_scene()
	
	print("Game Restarted")

# ========== MAIN MENU BUTTON ==========
func _on_main_menu_pressed():
	# Unpause sebelum pindah scene
	get_tree().paused = false
	
	# Ganti scene ke main menu (sesuaikan path-nya)
	get_tree().change_scene_to_file("res://UI/UI-Scene/Mainmenu2.tscn")
	
	print("Back to Main Menu")

# ========== SFX SLIDER ==========
func _on_sfx_changed(value: float):
	# Konversi dari 0-100 ke 0.0-1.0
	sfx_volume = value / 100.0
	
	# Set volume bus SFX
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		if sfx_volume > 0:
			AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
		else:
			AudioServer.set_bus_volume_db(sfx_bus, -80)  # Mute
	
	print("SFX Volume: ", sfx_volume)

# ========== MUSIC SLIDER ==========
func _on_music_changed(value: float):
	# Konversi dari 0-100 ke 0.0-1.0
	music_volume = value / 100.0
	
	# Set volume bus Music
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		if music_volume > 0:
			AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
		else:
			AudioServer.set_bus_volume_db(music_bus, -80)  # Mute
	
	print("Music Volume: ", music_volume)

# ========== ESC KEY TOGGLE ==========
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if get_tree().paused:
			resume_game()
		else:
			pause_game()


# ==============================================
# SCRIPT 2 (OPSIONAL): AudioManager.gd
# Attach ke: Node Autoload (Singleton)
# Untuk manage audio secara global
# ==============================================

# extends Node
# 
# func _ready():
# 	# Buat audio buses jika belum ada
# 	create_audio_buses()
# 
# func create_audio_buses():
# 	# Cek apakah bus SFX dan Music sudah ada
# 	if AudioServer.get_bus_index("SFX") == -1:
# 		AudioServer.add_bus()
# 		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
# 	
# 	if AudioServer.get_bus_index("Music") == -1:
# 		AudioServer.add_bus()
# 		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
