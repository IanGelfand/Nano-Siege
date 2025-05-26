extends Node3D

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_play_button_pressed() -> void:
	SoundManager.play_click()
	await get_tree().create_timer(0.05).timeout
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
