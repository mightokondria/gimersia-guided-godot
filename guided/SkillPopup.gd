extends CanvasLayer

@onready var message = $Message
var showing := false

func show_skill(text: String, duration := 1.8):
	if showing:
		return

	showing = true
	message.text = text
	visible = true
	message.modulate.a = 0.0  # <-- Fade Label, aman

	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 1.0, 0.4) # fade in
	tween.tween_interval(duration)
	tween.tween_property(message, "modulate:a", 0.0, 0.4) # fade out

	await tween.finished
	visible = false
	showing = false
