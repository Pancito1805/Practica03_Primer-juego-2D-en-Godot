extends RigidBody2D

var frozen: bool = false
var original_speed: Vector2
var original_modulate: Color

func _ready():
	$AnimatedSprite2D.play()
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
func freeze(duration):
	if frozen:
		return
	
	frozen = true
	original_speed = linear_velocity
	original_modulate = modulate
	
	# Efecto visual: azul y quieto
	linear_velocity = Vector2.ZERO
	modulate = Color(0.5, 0.8, 1.0, 1)
	
	# Timer para descongelar
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_thaw)
	timer.wait_time = duration
	add_child(timer)
	timer.start()
	
	print("🧊 Enemigo congelado")

func _on_thaw():
	frozen = false
	linear_velocity = original_speed
	modulate = original_modulate
	print("🔥 Enemigo descongelado")
