extends CanvasLayer
@onready var textbox_container: MarginContainer = $TexBoxContainer
@onready var label: Label = $TexBoxContainer/Panel/MarginContainer/HBoxContainer/Label


func _ready() -> void:
	hide_textbox() 
	add_text("cukimay")


func hide_textbox():
	label.text = ""
	textbox_container.hide()
	
	
func show_textbox():
	textbox_container.show()
	
func add_text(next_text):
	label.text = next_text
	show_textbox()
	
	# 1. Set teks awal jadi tidak terlihat
	label.visible_ratio = 0.0
	
	# 2. Buat Tween baru
	var tween = create_tween()
	
	# Hitung durasi: misal 0.05 detik per karakter
	var duration = label.text.length() * 0.05
	
	# 3. Atur animasi
	# tween_property(objek, "nama_properti", nilai_akhir, durasi)
	tween.tween_property(label, "visible_ratio", 1.0, duration)
