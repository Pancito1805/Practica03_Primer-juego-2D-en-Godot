extends Node2D

@export var animation_speed: float = 10.0  # FPS de la animación
@export var auto_delete: bool = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var timer = $Timer

func _ready():
	# Configurar y reproducir animación
	animated_sprite.sprite_frames.set_animation_speed("death", animation_speed)
	animated_sprite.play("death")
	
	# Autodestruirse cuando termine la animación
	if auto_delete:
		var anim_duration = animated_sprite.sprite_frames.get_frame_count("death") / animation_speed
		timer.wait_time = anim_duration + 0.1  # +0.1 para asegurar que termine
		timer.timeout.connect(queue_free)
		timer.start()
	
	print("💀 Animación de muerte iniciada")
