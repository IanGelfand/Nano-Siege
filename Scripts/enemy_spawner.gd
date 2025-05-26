extends Node3D

@export var enemy_scene: PackedScene
@export var base_enemies: int = 5
@export var growth_rate: float = 1.5
@export var max_per_spawn: int = 10
@export var round_interval: float = 3.0

@onready var table_long_2: Node3D = $"../table_long2"
@onready var label: Label = $"../CanvasLayer/TextureRect/Label"
@onready var wave_counter_label: Label = $"../CanvasLayer/WaveCounter/WaveCounterLabel"

var wave_number: int = 1
var total_to_spawn: int
var spawned_count: int
var alive_enemies: int
var enemies_killed: int = 0

@onready var spawn_timer: Timer = Timer.new()

func _ready():
	spawn_timer.wait_time = round_interval
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_wave()

func _process(delta: float) -> void:
	label.text = 'Score: %d' % enemies_killed
	wave_counter_label.text = 'Wave: %d' % wave_number

func start_wave():
	total_to_spawn = int(base_enemies * pow(growth_rate, wave_number - 1))
	spawned_count = 0
	alive_enemies = 0
	print("Starting wave %d — total enemies: %d" % [wave_number, total_to_spawn])
	spawn_timer.start()

func _on_spawn_timer_timeout():
	var to_spawn_now = min(max_per_spawn, total_to_spawn - spawned_count)

	var batch_positions: Array = []

	for i in range(to_spawn_now):
		var pos = get_spawn_position(batch_positions)
		batch_positions.append(pos)

		var e = enemy_scene.instantiate()
		e.global_transform.origin = pos
		e.scale = Vector3(0.1, 0.1, 0.1)
		add_child(e)

		spawned_count += 1
		alive_enemies += 1
		e.connect("die", Callable(self, "_on_enemy_die"))

	if spawned_count >= total_to_spawn:
		spawn_timer.stop()

func _on_enemy_die():
	alive_enemies -= 1
	enemies_killed += 1
	if spawned_count >= total_to_spawn and alive_enemies <= 0:
		wave_number += 1
		start_wave()

func get_spawn_position(existing_positions: Array) -> Vector3:
	var origin = table_long_2.global_transform.origin
	var half_x = 0.8
	var half_z = 1.8
	var spawn_y = origin.y

	var player_pos = $"../Knight".global_transform.origin
	var protection_radius = 0.5
	var min_spacing = 0.05

	for i in range(20):
		var rx = randf_range(-half_x, half_x)
		var rz = randf_range(-half_z, half_z)
		var pos = Vector3(origin.x + rx, spawn_y, origin.z + rz)

		if pos.distance_to(player_pos) < protection_radius:
			continue
		if is_too_close(pos, existing_positions, min_spacing):
			continue
		return pos

	return player_pos + Vector3(0, 0.1, -1.0)

func is_too_close(pos: Vector3, list: Array, dist: float) -> bool:
	for p in list:
		if pos.distance_to(p) < dist:
			return true
	return false
