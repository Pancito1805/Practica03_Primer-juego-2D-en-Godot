extends Area2D

signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var dash_speed = 150 # Velocidad del dash
@export var dash_duration = 0.03 # Duración del dash en segundos
@export var dash_cooldown = 1.0 # Tiempo de espera entre dashes

var screen_size # Size of the game window.
var can_dash = true
var is_dashing = false

func _ready():
	screen_size = get_viewport_rect().size
	hide()


func _process(delta):
	# Si está haciendo dash, no procesar movimiento normal
	if is_dashing:
		return
	
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed(&"move_right"):
		velocity.x += 1
	if Input.is_action_pressed(&"move_left"):
		velocity.x -= 1
	if Input.is_action_pressed(&"move_down"):
		velocity.y += 1
	if Input.is_action_pressed(&"move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	# Detectar dash (tecla Shift)
	if Input.is_action_just_pressed(&"dash") and can_dash and velocity.length() > 0:
		start_dash(velocity.normalized())

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = &"right"
		$AnimatedSprite2D.flip_v = false
		$Trail.rotation = 0
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = &"up"
		rotation = PI if velocity.y > 0 else 0


func start_dash(direction: Vector2):
	is_dashing = true
	can_dash = false
	
	# Guardar posición inicial
	var start_pos = position
	var target_pos = position + direction * dash_speed
	
	# Asegurar que no salga de la pantalla
	target_pos = target_pos.clamp(Vector2.ZERO, screen_size)
	
	# Crear y configurar el tween para el dash
	var dash_tween = create_tween()
	dash_tween.set_parallel(false) # Asegurar que no sea paralelo
	dash_tween.tween_property(self, "position", target_pos, dash_duration)
	
	# Opcional: animación durante el dash
	if direction.x != 0:
		$AnimatedSprite2D.animation = &"right"
		$AnimatedSprite2D.flip_h = direction.x < 0
	else:
		$AnimatedSprite2D.animation = &"up"
		rotation = PI if direction.y > 0 else 0
	$AnimatedSprite2D.play()
	
	# Esperar a que termine el dash
	await dash_tween.finished
	
	is_dashing = false
	
	# Esperar cooldown
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


func start(pos):
	position = pos
	rotation = 0
	show()
	$CollisionShape2D.disabled = false
	can_dash = true
	is_dashing = false


func _on_Player_body_entered(_body):
	if is_dashing:
		return # Ignorar colisiones durante el dash
	
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred(&"disabled", true)
