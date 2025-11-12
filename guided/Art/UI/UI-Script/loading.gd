# Loading.gd (attach ke root Control dari Loading.tscn)
extends Control

@export var target_path: String = "res://_Scenes/TheStage.tscn"
@export var min_display_time: float = 2.0
@export var threshold: float = 0.12

@onready var progress_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/ProgressBar
@onready var info_label: Label = $ColorRect/MarginContainer/VBoxContainer/Label

# internal state
var displayed_progress: float = 0.0
var target_progress: float = 0.0
var simulated: float = 0.0
var using_sim: bool = true
const SMOOTH_SPEED: float = 8.0

var start_ms: int = 0
var load_finished: bool = false
var loaded_packed: PackedScene = null  # <- beri tipe eksplisit

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	info_label.text = "Loading..."
	# mulai request loading background
	ResourceLoader.load_threaded_request(target_path)

func _process(delta: float) -> void:
	# ambil status & progress (disimpan ke array agar API mengisi nilainya)
	var p := [0.0]
	var status := ResourceLoader.load_threaded_get_status(target_path, p)

	# tentukan real vs simulated progress
	if p.size() > 0 and p[0] > 0.005:
		# ada progress nyata dari loader
		using_sim = false
		target_progress = clamp(p[0], 0.0, 1.0)
	elif using_sim:
		# simulasi sampai batas tertentu (tidak langsung ke 1.0)
		simulated = min(simulated + delta / 0.6, 0.95)
		target_progress = simulated

	# smoothing untuk visual progress
	displayed_progress = lerp(displayed_progress, target_progress, clamp(delta * SMOOTH_SPEED, 0.0, 1.0))
	progress_bar.value = displayed_progress * 100.0

	# status handling
	match status:
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			# tetap menampilkan progres
			pass
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			# baru sekali: ambil packed scene dan tween progress ke 1.0
			if not load_finished:
				# cast ke PackedScene untuk memastikan tipe
				loaded_packed = ResourceLoader.load_threaded_get(target_path) as PackedScene
				if loaded_packed:
					load_finished = true
					# tween displayed_progress ke 1.0 dengan cepat
					var t = create_tween()
					t.tween_property(self, "displayed_progress", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				else:
					# unexpected: packed tidak tersedia
					info_label.text = "Failed to get scene resource"
					push_error("Loading finished but ResourceLoader.load_threaded_get returned null or non-PackedScene for: %s" % target_path)
		ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
			info_label.text = "Load failed"
			push_error("Threaded load failed for: %s" % target_path)
		_:
			# THREAD_LOAD_INVALID_RESOURCE atau unknown — biarkan tampil dan jangan crash
			pass

	# jika sudah selesai loading & min display time terpenuhi -> ganti scene
	if load_finished:
		var elapsed := (Time.get_ticks_msec() - start_ms) / 1000.0
		# pastikan displayed_progress benar-benar mencapai 1.0 sebelum ganti
		if elapsed >= min_display_time and displayed_progress >= 0.999:
			if loaded_packed:
				get_tree().change_scene_to_packed(loaded_packed)
			else:
				info_label.text = "No scene to switch to"
