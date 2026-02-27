extends CanvasLayer

func _ready():
	hide()  # Oculta al inicio, es correcto

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible

	# Opcional: para mejor UX, centra el mouse o muestra cursor si quieres
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Si tu juego usa mouse capturado

# Conexiones de botones (asegúrate que los nombres coincidan con tus nodos)
func _on_Reanudar_pressed():
	toggle_pause()

func _on_Reiniciar_pressed():
	toggle_pause()
	get_tree().reload_current_scene()

func _on_Salir_pressed():
	get_tree().quit()
