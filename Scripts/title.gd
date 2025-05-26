extends Label

@export var amplitude: float = 5.0
@export var frequency: float = 0.5

var _base_pos: Vector2
var _time: float = 0.0

func _ready() -> void:
	_base_pos = position

func _process(delta: float) -> void:
	_time += delta
	var angle = _time * frequency * TAU
	position.y = _base_pos.y + sin(angle) * amplitude
