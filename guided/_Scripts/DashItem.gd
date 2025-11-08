extends Area2D

# Jangan lupa hubungkan sinyal 'body_entered' ke fungsi ini!
func _on_body_entered(body):
	# Cek apakah 'body' punya metode "enable_dash"
	if body.has_method("enable_dash"):

		# 1. Panggil fungsi di script player
		body.enable_dash()

		# 2. Hancurkan item ini
		queue_free()
