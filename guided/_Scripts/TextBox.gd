extends CanvasLayer

signal finished()

@onready var textbox_container: MarginContainer = $TexBoxContainer
@onready var label: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Label
@onready var start_symbol: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Start
@onready var end_symbol: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/End
# Referensi baru untuk potret
@onready var portrait: TextureRect = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Portrait

enum State {
	READY,
	READING,
	FINISHED
}

var currrent_state = State.READY
var text_queue = []
var tween: Tween

func _ready() -> void:
	print("Starting State: State.READY")
	hide_textbox()
	# Contoh penggunaan baru dengan potret (opsional, Anda bisa sesuaikan cara Anda memanggilnya)
	# queue_text("Halo, saya Sensei!", "sensei_happy")
	# queue_text("Dan ini murid saya.", "player_neutral")

func _process(_delta: float) -> void:
	match currrent_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				label.visible_ratio = 1.0
				if tween: tween.kill()
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
				change_state(State.READY)
				hide_textbox()

# Modifikasi queue_text untuk menerima nama potret opsional
func queue_text(next_text, portrait_name = ""):
	text_queue.push_back({ "text": next_text, "portrait": portrait_name })

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	# Sembunyikan potret juga saat textbox sembunyi
	portrait.hide()
	textbox_container.hide()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	var next_data = text_queue.pop_front()
	# Menangani data teks yang mungkin berupa string lama atau objek baru
	var next_text = ""
	var portrait_name = ""
	
	if typeof(next_data) == TYPE_DICTIONARY:
		next_text = next_data["text"]
		portrait_name = next_data["portrait"]
	else:
		next_text = next_data
	
	label.text = next_text
	
	# Update potret
	if portrait_name != "":
		var portrait_path = "res://art/portraits/" + portrait_name + ".png"
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
			portrait.show()
		else:
			portrait.hide()
			print("Potret tidak ditemukan: " + portrait_path)
	else:
		portrait.hide()
		
	change_state(State.READING)
	show_textbox()
	
	label.visible_ratio = 0.0
	var duration = label.text.length() * 0.05
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	end_symbol.text = "v"
	change_state(State.FINISHED)

func change_state(next_state):
	currrent_state = next_state
	# ... (print debug Anda)
