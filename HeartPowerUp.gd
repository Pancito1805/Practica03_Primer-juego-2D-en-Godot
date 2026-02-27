extends Area2D  

signal collected

@export var heal_amount: int = 1
@export var pickup_sound: AudioStream

var collected_flag: bool = false
var main_node = null

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Grupos
	add_to_group("powerup")
	add_to_group("heart_powerup")
	
	# Configuración de Area2D
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1
	
	# Conectar señales
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# Buscar Main - MÉTODO MÁS DIRECTO
	main_node = get_node("/root/Main")
	if not main_node:
		main_node = get_tree().current_scene
	
	if main_node:
		print("✅ Heart - Main encontrado: ", main_node.name)
	else:
		print("⚠️ Heart - No se encontró Main")
	
	# Verificar si el sonido está asignado
	if pickup_sound:
		print("❤️ Heart - Sonido asignado: ", pickup_sound.resource_path)
	else:
		print("⚠️ Heart - No hay sonido asignado en el Inspector")
	
	# Animación flotante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", sprite.position.y - 10, 1.0)
	tween.tween_property(sprite, "position:y", sprite.position.y, 1.0)

func _on_body_entered(body):
	if collected_flag:
		return
	if body.is_in_group("player"):
		recoger(body)

func _on_area_entered(area):
	if collected_flag:
		return
	if area.is_in_group("player"):
		recoger(area)

func recoger(player):
	collected_flag = true
	print("✅ ¡CORAZÓN RECOGIDO!")
	
	# Curar al jugador
	if player.has_method("heal"):
		player.heal(heal_amount)
	
	collected.emit()
	
	# 🔊 REPRODUCIR SONIDO - VERSIÓN MEJORADA
	if pickup_sound:
		print("🔊 Heart - Intentando reproducir sonido")
		
		# Buscar Main directamente aquí también
		var main = get_node("/root/Main")
		if not main:
			main = get_tree().current_scene
		
		if main and main.has_method("play_heart_pickup_sound"):
			print("🔊 Heart - Llamando a play_heart_pickup_sound")
			main.play_heart_pickup_sound(pickup_sound)
		else:
			print("⚠️ Heart - Main no tiene método play_heart_pickup_sound")
	else:
		print("⚠️ Heart - pickup_sound es null")
	
	queue_free()
