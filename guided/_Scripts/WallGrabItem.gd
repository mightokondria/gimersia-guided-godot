extends Area2D

# Jangan lupa hubungkan sinyal 'body_entered' ke fungsi ini!
func _on_body_entered(body):
	# Cek apakah 'body' punya metode "enable_wall_grab"
	if body.has_method("enable_wall_grab"):

		# 1. Panggil fungsi di script player
		body.enable_wall_grab()

		# 2. Hancurkan item ini
		queue_free()
