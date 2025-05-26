extends CanvasLayer

@onready var score: Label = $PanelContainer/VBoxContainer/Score
@onready var enemy_spawner: Node3D = $"../EnemySpawner"

func _process(delta: float) -> void:
	score.text = "Score: %d" % enemy_spawner.enemies_killed

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_end_pressed() -> void:
	get_tree().quit()
