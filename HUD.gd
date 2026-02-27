extends CanvasLayer

signal start_game

@onready var score_label = $ScoreLabel
@onready var message_label = $MessageLabel
@onready var message_timer = $MessageTimer
@onready var start_button = $StartButton
@onready var health_label = $HealthLabel

func _ready():
	if not health_label:
		health_label = Label.new()
		health_label.name = "HealthLabel"
		health_label.position = Vector2(10, 50)
		health_label.add_theme_color_override("font_color", Color.RED)
		health_label.add_theme_font_size_override("font_size", 24)
		add_child(health_label)
	
	message_label.hide()

func show_message(text):
	message_label.text = text
	message_label.show()
	message_timer.start()

func show_game_over():
	show_message("Game Over")
	await message_timer.timeout
	message_label.text = "Dodge the\nCreeps"
	message_label.show()
	await get_tree().create_timer(1).timeout
	start_button.show()

func update_score(score):
	score_label.text = str(score)

func update_health(health):
	var heart_text = ""
	for i in range(3):
		if i < health:
			heart_text += "❤️ "
		else:
			heart_text += "🖤 "
	health_label.text = "Vida: " + heart_text

func _on_StartButton_pressed():
	start_button.hide()
	start_game.emit()

func _on_MessageTimer_timeout():
	message_label.hide()
