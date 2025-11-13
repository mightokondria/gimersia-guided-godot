extends Node

var music_player: AudioStreamPlayer

# Path lagu utama (1 lagu untuk seluruh game)
const MAIN_MUSIC = "res://Audio/BGM/outdoor_background_music_final.mp3"

func _ready():
	# Buat audio player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Load musik
	var stream = load(MAIN_MUSIC)
	if stream is AudioStream:
		stream.loop = true  # looping wajib aktif
	music_player.stream = stream

	# Mulai putar (hanya sekali!)
	music_player.play()
