extends CharacterBody2D

var move_speed := 500.0
var target: Node2D = null
var active := false

func start_running(t: Node2D, speed := 500.0):
	target = t
	move_speed = speed
	active = true

func stop_running():
	active = false
	velocity = Vector2.ZERO

func _physics_process(_delta):
	if active and target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
