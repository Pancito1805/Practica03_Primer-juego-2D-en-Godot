extends CanvasLayer

@onready var score_label: Label = $VBoxContainer/ScoreLabel

func _ready():
	hide()  # Oculta al inicio

func show_game_over(final_score: int):
	score_label.text = "Puntuación: " + str(final_score)
	show()

func _on_Reiniciar_pressed():
	get_tree().reload_current_scene()

func _on_Salir_pressed():
	get_tree().quit()
