extends Area2D

# Kita akan menghubungkan sinyal ke fungsi ini
func _on_body_entered(body):
	# Cek apakah 'body' yang masuk punya fungsi 'enable_double_jump'?
	# Ini adalah cara paling aman untuk memastikan itu adalah Player kita.
	if body.has_method("enable_double_jump"):

		# 1. Panggil fungsi di script player
		body.enable_double_jump()

		# 2. Hancurkan item ini agar tidak bisa diambil lagi
		queue_free()
