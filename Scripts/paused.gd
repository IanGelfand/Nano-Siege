extends CanvasLayer

@onready var paused: CanvasLayer = $"."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if paused.visible == false:
			SoundManager.play_pause()
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			paused.visible = true
		else:
			get_tree().paused = false
			SoundManager.play_unpause()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			paused.visible = false

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	SoundManager.play_unpause()
	paused.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
