extends CanvasLayer

# --- SINYAL KUSTOM ---
signal dialog_finished() # Dikirim saat SEMUA dialog selesai

# --- REFERENSI NODE ---
@onready var background = $MarginContainer/Background
@onready var portrait = $MarginContainer/MarginContainer/HBoxContainer/Portrait
@onready var name_label = $MarginContainer/MarginContainer/HBoxContainer/VBoxContainer/Label
@onready var text_label = $MarginContainer/MarginContainer/HBoxContainer/VBoxContainer/RichTextLabel

# --- VARIABEL DATA ---
var dialog_data = []    # Menyimpan semua data dari JSON
var current_index = 0   # Menunjuk ke baris dialog keberapa sekarang
var is_typing = false   # Apakah teks sedang efek mengetik?
var tween: Tween

func _ready():
	hide_dialog() # Sembunyikan saat game mulai

func _process(_delta):
	# Cek input HANYA jika dialog sedang aktif (muncul)
	if background.visible and Input.is_action_just_pressed("ui_accept"):
		if is_typing:
			# Kalau sedang ngetik dan dipencet -> SKIP ngetik
			skip_typing()
		else:
			# Kalau sudah selesai ngetik dan dipencet -> LANJUT dialog berikutnya
			show_next_line()

# --- FUNGSI UTAMA: MULAI DIALOG ---
# Fungsi ini yang akan dipanggil dari luar (misal dari CutsceneTrigger)
func start_dialog(json_path: String):
	dialog_data = load_json(json_path)
	if dialog_data.size() > 0:
		current_index = -1 # Mulai dari -1 agar saat show_next_line() jadi 0
		background.show()
		show_next_line()
	else:
		print("ERROR: Data dialog kosong atau gagal dimuat!")

# --- FUNGSI NAVIGASI DIALOG ---
func show_next_line():
	current_index += 1
	
	# Cek apakah masih ada dialog tersisa?
	if current_index < dialog_data.size():
		# Ambil data baris saat ini
		var line_data = dialog_data[current_index]
		
		# 1. Set Nama
		name_label.text = line_data["name"]
		
		# 2. Set Teks & Mulai Animasi Ketik
		text_label.text = line_data["text"]
		start_typing_effect()
		
		# 3. Set Potret (Opsional, perlu penyesuaian path)
		# Asumsi: gambar ada di folder "res://Art/Portraits/"
		var portrait_path = "res://Art/Portraits/" + line_data["portrait"] + ".png"
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
		else:
			# Jika tidak ada gambar khusus, bisa dikosongkan atau pakai default
			portrait.texture = null 
			
	else:
		# Dialog sudah habis
		finish_dialog()

func finish_dialog():
	hide_dialog()
	dialog_finished.emit() # Beritahu game bahwa dialog selesai

# --- FUNGSI EFEK KETIK ---
func start_typing_effect():
	is_typing = true
	text_label.visible_ratio = 0.0
	
	if tween: tween.kill()
	tween = create_tween()
	
	# Kecepatan: 0.05 detik per huruf
	var duration = text_label.text.length() * 0.05
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	
	# Saat tween selesai normal
	tween.finished.connect(_on_typing_finished)

func skip_typing():
	if tween: tween.kill()
	text_label.visible_ratio = 1.0
	is_typing = false

func _on_typing_finished():
	is_typing = false

func hide_dialog():
	background.hide()

# --- FUNGSI PEMBANTU: LOAD JSON ---
#func load_json(file_path: String):
	#if not FileAccess.file_exists(file_path):
		#print("ERROR: File JSON tidak ditemukan di ", file_path)
		#return []
		#
	#var file = FileAccess.open(file_path, FileAccess.READ)
	#var json_string = file.get_as_text()
	#var json = JSON.new()
	#var error = json.parse(json_string)
	#
	#if error == OK:
		#return json.data if typeof(json.data) == TYPE_ARRAY else []
	#else:
		#print("ERROR: Gagal parsing JSON di baris ", json.get_error_line())
		#return []
