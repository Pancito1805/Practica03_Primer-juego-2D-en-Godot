extends Area2D

signal hit
signal health_changed(current_health)

@export var death_animation_scene: PackedScene
@export var speed: float = 400.0
@export var dash_speed: float = 150.0
@export var dash_duration: float = 0.03
@export var dash_cooldown: float = 1.0
@export var max_health: int = 3
@export var projectile_scene: PackedScene  # Arrastrar Projectile.tscn aquí
@export var projectile_cooldown: float = 0.3  # Tiempo entre disparos
var can_shoot: bool = true
# Variables para el escudo
var shielded: bool = false
@export var shield_duration: float = 5.0
var shield_timer: Timer

# Variables para escarcha (NUEVAS - DECLARADAS AQUÍ)
var frost_active: bool = false
var frost_duration: float = 3.0
var frost_timer: Timer

var current_health: int
var screen_size
var can_dash: bool = true
var is_dashing: bool = false

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	add_to_group("player")
	
	# Configuración de colisión - DEBE DETECTAR CAPA 2
	collision_layer = 1
	collision_mask = 1 | 2 | 4  # Capas 1, 2 y 3
	
	current_health = max_health
	hide()
	
	# Crear timer para el escudo
	shield_timer = Timer.new()
	shield_timer.one_shot = true
	shield_timer.timeout.connect(_on_shield_timeout)
	add_child(shield_timer)
	
	# Crear timer para escarcha
	frost_timer = Timer.new()
	frost_timer.one_shot = true
	frost_timer.timeout.connect(_on_frost_timeout)
	add_child(frost_timer)
	
	print("👤 Player - Mask: ", collision_mask, " (debe incluir capa 2)")

# Nuevo método para activar escarcha
func activate_frost(duration):
	frost_active = true
	frost_duration = duration
	
	# Efecto visual azul claro
	modulate = Color(0.5, 0.8, 1.0, 1)
	print("❄️ ESCARCHA ACTIVADA - Congelando enemigos por ", duration, "s")
	
	# Congelar enemigos existentes
	freeze_all_enemies()
	
	# Iniciar timer
	frost_timer.start(duration)

func freeze_all_enemies():
	var enemies = get_tree().get_nodes_in_group("mobs")
	for enemy in enemies:
		if enemy.has_method("freeze"):
			enemy.freeze(frost_duration)
		else:
			# Si no tienen método freeze, los ralentizamos
			enemy.linear_velocity = enemy.linear_velocity * 0.1

func _on_frost_timeout():
	frost_active = false
	modulate = Color.WHITE
	print("☀️ Escarcha desactivada")

func _process(delta):
	if is_dashing:
		return
	
	var velocity = Vector2.ZERO
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

	if Input.is_action_just_pressed(&"dash") and can_dash and velocity.length() > 0:
		start_dash(velocity.normalized())

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		# Movimiento horizontal
		$AnimatedSprite2D.animation = &"right"
		$AnimatedSprite2D.flip_v = false  # Sin volteo vertical
		$Trail.rotation = 0
		$AnimatedSprite2D.flip_h = velocity.x < 0  # Volteo horizontal según dirección
	elif velocity.y != 0:
		# Movimiento vertical - USAR FLIP_V EN LUGAR DE ROTACIÓN
		$AnimatedSprite2D.animation = &"up"
		$AnimatedSprite2D.flip_h = false  # Sin volteo horizontal
		$Trail.rotation = 0
		$AnimatedSprite2D.flip_v = velocity.y > 0
	# Disparo
	if Input.is_action_just_pressed(&"shoot"):  # Necesitas configurar esta acción
		shoot()

func start_dash(direction: Vector2):
	is_dashing = true
	can_dash = false
	
	var target_pos = position + direction * dash_speed
	target_pos = target_pos.clamp(Vector2.ZERO, screen_size)
	
	var dash_tween = create_tween()
	dash_tween.set_parallel(false)
	dash_tween.tween_property(self, "position", target_pos, dash_duration)
	
	if direction.x != 0:
		$AnimatedSprite2D.animation = &"right"
		$AnimatedSprite2D.flip_h = direction.x < 0
	else:
		$AnimatedSprite2D.animation = &"up"
		rotation = PI if direction.y > 0 else 0
	$AnimatedSprite2D.play()
	
	await dash_tween.finished
	is_dashing = false
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func start(pos):
	position = pos
	rotation = 0
	show()
	$CollisionShape2D.disabled = false
	can_dash = true
	is_dashing = false
	current_health = max_health
	shielded = false
	frost_active = false
	modulate = Color.WHITE
	health_changed.emit(current_health)
	print("🏁 Juego iniciado - Vida: ", current_health)

# Activar escudo
func activate_shield():
	shielded = true
	modulate = Color(0.3, 0.6, 1.0, 1)  # Azul
	print("🛡️ ESCUDO ACTIVADO por ", shield_duration, " segundos")
	shield_timer.start(shield_duration)

# Desactivar escudo
func _on_shield_timeout():
	shielded = false
	modulate = Color.WHITE
	print("⏰ Escudo desactivado")

func _on_body_entered(body):
	# Ignorar si está en dash
	if is_dashing:
		return
	
	# Los power-ups se manejan ellos mismos
	if body.is_in_group("powerup"):
		print("👤 Player tocó power-up, pero lo maneja el power-up")
		return
	
	# Procesar mobs
	if body.is_in_group("mobs"):
		if shielded:
			print("⚔️ Escudo activo - mob destruido")
			body.queue_free()
			shielded = false
			modulate = Color.WHITE
			shield_timer.stop()
		else:
			current_health -= 1
			modulate = Color.RED
			health_changed.emit(current_health)
			print("💥 Daño recibido - Vida: ", current_health)
			
			# 🔊 REPRODUCIR SONIDO DE DAÑO
			var main = get_node("/root/Main")
			if not main:
				main = get_tree().current_scene
			if main and main.has_method("play_hurt_sound"):
				main.play_hurt_sound()
				print("🔊 Sonido de daño enviado a Main")
			
			await get_tree().create_timer(0.2).timeout
			modulate = Color.WHITE
			
			if current_health <= 0:
				print("💀 Jugador murió")
				create_death_animation()
				hide()
				hit.emit()
				$CollisionShape2D.set_deferred("disabled", true)
#Método para crear animación de muerte
func create_death_animation():
	if death_animation_scene:
		var death_anim = death_animation_scene.instantiate()
		death_anim.global_position = global_position
		death_anim.z_index = 100  # Asegurar que esté delante
		get_parent().add_child(death_anim)
		print("🎬 Animación de muerte creada en: ", global_position)
	else:
		print("⚠️ No hay escena de animación de muerte asignada")

# MÉTODO HEAL - PARA CURAR AL JUGADOR
func heal(amount):
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	
	# Efecto visual verde
	modulate = Color.GREEN
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE
	
	# Emitir señal de cambio
	health_changed.emit(current_health)
	
	print("❤️ CURADO: ", old_health, " → ", current_health, " (+", amount, ")")


func shoot():
	if not can_shoot or not projectile_scene:
		return
	
	print("🎯 Disparando")
	
	# Determinar dirección
	var shoot_direction = Vector2.RIGHT
	
	if Input.is_action_pressed(&"move_right"):
		shoot_direction = Vector2.RIGHT
		$ProjectileOrigin.position = Vector2(30, 0)  # Ajusta estos valores
	elif Input.is_action_pressed(&"move_left"):
		shoot_direction = Vector2.LEFT
		$ProjectileOrigin.position = Vector2(-30, 0)
	elif Input.is_action_pressed(&"move_down"):
		shoot_direction = Vector2.DOWN
		$ProjectileOrigin.position = Vector2(0, 30)
	elif Input.is_action_pressed(&"move_up"):
		shoot_direction = Vector2.UP
		$ProjectileOrigin.position = Vector2(0, -30)
	else:
		# Usar dirección de la animación
		if $AnimatedSprite2D.animation == "right":
			if not $AnimatedSprite2D.flip_h:
				shoot_direction = Vector2.RIGHT
				$ProjectileOrigin.position = Vector2(30, 0)
			else:
				shoot_direction = Vector2.LEFT
				$ProjectileOrigin.position = Vector2(-30, 0)
		elif $AnimatedSprite2D.animation == "up":
			if rotation == 0:
				shoot_direction = Vector2.UP
				$ProjectileOrigin.position = Vector2(0, -30)
			else:
				shoot_direction = Vector2.DOWN
				$ProjectileOrigin.position = Vector2(0, 30)
	
	# Instanciar proyectil
	var projectile = projectile_scene.instantiate()
	
	# Configurar dirección
	projectile.direction = shoot_direction
	
	# ✅ USAR LA POSICIÓN ACTUALIZADA DEL MARKER
	projectile.global_position = $ProjectileOrigin.global_position
	
	print("  Jugador: ", global_position)
	print("  Marker: ", $ProjectileOrigin.global_position)
	print("  Proyectil: ", projectile.global_position)
	
	# Agregar a la escena
	get_parent().add_child(projectile)
	
	# Cooldown
	can_shoot = false
	await get_tree().create_timer(projectile_cooldown).timeout
	can_shoot = true
