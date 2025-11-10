extends CanvasLayer

signal finished()

@onready var textbox_container: MarginContainer = $TexBoxContainer
@onready var label: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Label
@onready var start_symbol: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Start
@onready var end_symbol: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/End
@onready var portrait: TextureRect = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Portrait



enum State { READY, READING, FINISHED }

var currrent_state = State.READY
var text_queue = []
var tween: Tween  # <-- HANYA DEKLARASI, JANGAN create_tween() DI SINI

func _ready() -> void:
	print("Starting State: State.READY")
	hide_textbox()
	queue_text("satu cukimay")
	queue_text("dua cukimay")
	queue_text("tiga cukimay")
	queue_text("eempat cukimay")

func _process(_delta: float) -> void:
	match currrent_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				# SKIP ANIMASI
				label.visible_ratio = 1.0
				if tween: tween.kill() # Gunakan kill() untuk memastikan tween mati total
				end_symbol.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				if text_queue.is_empty():
					change_state(State.READY)
					hide_textbox()
					finished.emit()
				else:
					change_state(State.READY)
					#display_text()

func queue_text(next_text):
	text_queue.push_back(next_text)

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	var next_text = text_queue.pop_front()
	label.text = next_text
	change_state(State.READING)
	show_textbox()
	update_portrait("sensei_happy")
	
	label.visible_ratio = 0.0
	var duration = label.text.length() * 0.05
	
	# --- PERBAIKAN DI SINI ---
	# 1. Pastikan tween lama mati dulu (jika ada)
	if tween: tween.kill()
	
	# 2. BUAT TWEEN BARU SETIAP KALI TEKS MUNCUL
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)
	
	# 3. (Opsional tapi bagus) Otomatis pindah ke FINISHED saat tween selesai
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	end_symbol.text = "v"
	change_state(State.FINISHED)

func change_state(next_state):
	currrent_state = next_state
	# ... (print debug Anda)
	
	
# Di fungsi yang menampilkan teks (misal show_next_line atau queue_text tadi):
func update_portrait(character_name):
	# Contoh logika sederhana:
	var portrait_path = "res://Art/Portraits/" + character_name + ".png"
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
		portrait.show()
	else:
		# Sembunyikan jika tidak ada gambar agar teks melebar penuh
		portrait.hide()
