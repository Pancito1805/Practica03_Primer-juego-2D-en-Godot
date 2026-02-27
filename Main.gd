extends Node

@export var mob_scenes: Array[PackedScene]
@export var powerup_scenes: Array[PackedScene]
@export var heart_powerup_scenes: Array[PackedScene]
@export var frost_powerup_scenes: Array[PackedScene]
@export var projectile_scene: PackedScene  # Arrastrar Projectile.tscn aquí
@export var projectile_cooldown: float = 0.3  # Tiempo entre disparos
@export var hurt_sound: AudioStream 

# Señales para los sonidos 
signal heart_sound_played(sound_stream)
signal shield_sound_played(sound_stream)
signal frost_sound_played(sound_stream)

var score: int = 0
var screen_size: Vector2
var can_shoot: bool = true
@onready var hud = $HUD
@onready var game_over_screen: CanvasLayer = $GameOver
@onready var player = $Player
@onready var powerup_timer: Timer = $PowerUpTimer
@onready var heart_timer: Timer = $HeartTimer
@onready var frost_timer: Timer = $FrostTimer
@onready var music = $Music
@onready var death_sound = $DeathSound
@onready var pickup_sound_player = $PickupSoundPlayer

func _ready():
	game_over_screen.hide()
	screen_size = get_viewport().get_visible_rect().size
	
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	
	# Configurar timers
	if heart_timer:
		heart_timer.wait_time = 15.0
		if not heart_timer.timeout.is_connected(_on_HeartTimer_timeout):
			heart_timer.timeout.connect(_on_HeartTimer_timeout)
	
	if frost_timer:
		frost_timer.wait_time = 20.0
		if not frost_timer.timeout.is_connected(_on_FrostTimer_timeout):
			frost_timer.timeout.connect(_on_FrostTimer_timeout)
	
	print("✅ Main listo")

# MÉTODOS PARA REPRODUCIR SONIDOS 

# NUEVO: Método para reproducir sonido de daño
func play_hurt_sound():
	if pickup_sound_player and hurt_sound:
		pickup_sound_player.stream = hurt_sound
		pickup_sound_player.play()
		print("🔊 Sonido de DAÑO reproducido")

func play_heart_pickup_sound(sound_stream):
	print("🔴 MAIN - play_heart_pickup_sound llamado")
	print("   pickup_sound_player: ", pickup_sound_player != null)
	print("   sound_stream: ", sound_stream != null)
	
	if pickup_sound_player and sound_stream:
		pickup_sound_player.stream = sound_stream
		pickup_sound_player.play()
		print("🔊 ¡SONIDO REPRODUCIÉNDOSE!")
	else:
		print("⚠️ ERROR: No se puede reproducir")
		
func play_frost_pickup_sound(sound_stream):
	if pickup_sound_player and sound_stream:
		pickup_sound_player.stream = sound_stream
		pickup_sound_player.play()
		print("🔊 Sonido de ESCARCHA reproducido")
		frost_sound_played.emit(sound_stream)

func play_shield_pickup_sound(sound_stream):
	if pickup_sound_player and sound_stream:
		pickup_sound_player.stream = sound_stream
		pickup_sound_player.play()
		print("🔊 Sonido de ESCUDO reproducido")
		shield_sound_played.emit(sound_stream)
		
func _on_player_health_changed(health):
	hud.update_health(health)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	powerup_timer.stop()
	if heart_timer:
		heart_timer.stop()
	if frost_timer:
		frost_timer.stop()
	hud.hide()
	music.stop()
	death_sound.play()
	game_over_screen.show_game_over(score)

func new_game():
	get_tree().call_group("mobs", "queue_free")
	score = 0
	player.start($StartPosition.position)
	$StartTimer.start()
	hud.update_score(score)
	hud.show_message("Get Ready")
	music.play()
	game_over_screen.hide()
	
	powerup_timer.start()
	if heart_timer:
		heart_timer.start()
	if frost_timer:
		frost_timer.start()

func _on_MobTimer_timeout():
	if mob_scenes.is_empty():
		return
		
	var mob_scene = mob_scenes.pick_random()
	var mob = mob_scene.instantiate()
	
	var mob_spawn_location = get_node(^"MobPath/MobSpawnLocation")
	mob_spawn_location.progress = randi()
	
	var direction = mob_spawn_location.rotation + PI / 2
	mob.position = mob_spawn_location.position
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	
	var min_speed = mob.get("min_speed") if "min_speed" in mob else 150.0
	var max_speed = mob.get("max_speed") if "max_speed" in mob else 250.0
	var velocity = Vector2(randf_range(min_speed, max_speed), 0.0)
	mob.linear_velocity = velocity.rotated(direction)
	
	mob.add_to_group("mobs")
	add_child(mob)

func _on_ScoreTimer_timeout():
	score += 1
	hud.update_score(score)

func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()

func _on_PowerUpTimer_timeout():
	if powerup_scenes.is_empty():
		return
		
	var powerup_scene = powerup_scenes.pick_random()
	var powerup = powerup_scene.instantiate()
	
	powerup.position = Vector2(
		randf_range(100, screen_size.x - 100),
		randf_range(100, screen_size.y - 100)
	)
	
	add_child(powerup)
	print("✨ Power-up creado")

func _on_HeartTimer_timeout():
	if heart_powerup_scenes.is_empty():
		return
	
	var heart_scene = heart_powerup_scenes.pick_random()
	var heart = heart_scene.instantiate()
	
	heart.position = Vector2(
		randf_range(100, screen_size.x - 100),
		randf_range(100, screen_size.y - 100)
	)
	
	add_child(heart)
	print("❤️ Corazón apareció")

func _on_FrostTimer_timeout():
	if frost_powerup_scenes.is_empty():
		return
	
	var frost_scene = frost_powerup_scenes.pick_random()
	var frost = frost_scene.instantiate()
	
	frost.position = Vector2(
		randf_range(100, screen_size.x - 100),
		randf_range(100, screen_size.y - 100)
	)
	
	add_child(frost)
	print("❄️ Escarcha apareció")

func _on_player_hit():
	game_over()
