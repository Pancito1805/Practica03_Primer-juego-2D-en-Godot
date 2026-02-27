extends Area2D

signal collected

@export var freeze_duration: float = 3.0
@export var pickup_sound: AudioStream

var collected_flag: bool = false
var main_node = null

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Grupos
	add_to_group("powerup")
	add_to_group("frost_powerup")
	
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
	
	# Buscar Main
	main_node = get_node("/root/Main")
	if not main_node:
		main_node = get_tree().current_scene
	
	if main_node:
		print("✅ Frost - Main encontrado: ", main_node.name)
	else:
		print("⚠️ Frost - No se encontró Main")
	
	# Verificar sonido
	if pickup_sound:
		print("❄️ Frost - Sonido asignado: ", pickup_sound.resource_path)
	else:
		print("⚠️ Frost - No hay sonido asignado en el Inspector")
	
	# Animación flotante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", sprite.position.y - 10, 1.0)
	tween.tween_property(sprite, "position:y", sprite.position.y, 1.0)
	
	sprite.self_modulate = Color(0.5, 0.8, 1.0, 1)
	
	print("❄️ Escarcha creada")

func _on_body_entered(body):
	if collected_flag or not body.is_in_group("player"):
		return
	recoger(body)

func _on_area_entered(area):
	if collected_flag or not area.is_in_group("player"):
		return
	recoger(area)

func recoger(player):
	collected_flag = true
	print("❄️ ¡ESCARCHA RECOGIDA!")
	
	if player.has_method("activate_frost"):
		player.activate_frost(freeze_duration)
	
	collected.emit()
	
	# 🔊 REPRODUCIR SONIDO
	if pickup_sound:
		print("🔊 Frost - Intentando reproducir sonido")
		
		var main = get_node("/root/Main")
		if not main:
			main = get_tree().current_scene
		
		if main and main.has_method("play_frost_pickup_sound"):
			print("🔊 Frost - Llamando a play_frost_pickup_sound")
			main.play_frost_pickup_sound(pickup_sound)
		else:
			print("⚠️ Frost - Main no tiene método play_frost_pickup_sound")
	else:
		print("⚠️ Frost - pickup_sound es null")
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_property(collision_shape, "disabled", true, 0)
	
	await tween.finished
	queue_free()
