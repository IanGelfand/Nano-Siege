extends Node

@onready var confirm: AudioStreamPlayer3D = $Confirm
@onready var paused: AudioStreamPlayer3D = $Paused
@onready var unpause: AudioStreamPlayer3D = $Unpause
@onready var attack: AudioStreamPlayer3D = $Attack
@onready var step_wood: AudioStreamPlayer3D = $StepWood

func play_click():
	confirm.play()

func play_pause():
	paused.play()

func play_unpause():
	unpause.play()

func play_attack():
	attack.play()

func play_step_wood(vol: float = 0.0):
	if vol:
		step_wood.volume_db = vol
	step_wood.play()
