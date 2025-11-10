extends CharacterBody2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D


func _ready() -> void:
	sprite_2d.play("sensei_idle")
	
