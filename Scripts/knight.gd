extends CharacterBody3D
class_name Knight

signal die

@export var SPEED: float = 8.0
@export var ACCELERATION: float = 8.0
@export var JUMP_SPEED: float = 2.0
@export var ROTATION_SPEED: float = 12.0
@export var MOUSE_SENSITIVITY: float = 0.0015
@export var GRAVITY_SCALE: float = 0.5
@export var FOOTSTEP_INTERVAL: float = 0.4
@export var max_health: int = 5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * GRAVITY_SCALE
var jumping = false
var last_floor = true
var can_play_animation: bool = true
var is_attacking: bool = false
var current_health: int
var has_hit_during_attack: bool = false

@export var regen_delay: float = 5.0
var regen_timer := 0.0
var attacks = [
	'1H_Melee_Attack_Slice_Horizontal'
]

@onready var rig: Node3D = $Rig
@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = $AnimationTree.get('parameters/playback')
@onready var footstep_timer: Timer = $FootstepTimer
@onready var health_ui: HBoxContainer = $"../CanvasLayer/Health"

func _ready() -> void:
	current_health = max_health
	_update_health_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	footstep_timer.one_shot = true
	footstep_timer.wait_time = FOOTSTEP_INTERVAL
	footstep_timer.timeout.connect(_on_FootstepTimer_timeout)

func _physics_process(delta: float) -> void:
	velocity.y += -gravity * delta
	_get_move_input(delta)
	move_and_slide()

	var is_walking = is_on_floor() and velocity.length() > 0.1
	if is_walking and footstep_timer.is_stopped():
		footstep_timer.start()
	elif not is_walking and not footstep_timer.is_stopped():
		footstep_timer.stop()

	if velocity.length() > 0.1:
		rig.rotation.y = lerp_angle(rig.rotation.y, spring_arm_3d.rotation.y, ROTATION_SPEED * delta)

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		jumping = true
		animation_tree.set("parameters/conditions/grounded", false)
		animation_tree.set("parameters/conditions/jumping", true)
		await get_tree().create_timer(0.4).timeout
		velocity.y = JUMP_SPEED

	if is_on_floor() and not last_floor:
		jumping = false
		animation_tree.set("parameters/conditions/jumping", false)
		animation_tree.set("parameters/conditions/grounded", true)
	last_floor = is_on_floor()

	if not is_on_floor() and not jumping:
		animation_state.travel("Jump_Idle")
		animation_tree.set("parameters/conditions/grounded", false)
		
	if current_health < max_health:
		regen_timer += delta
		if regen_timer >= regen_delay:
			current_health += 1
			_update_health_ui()
			regen_timer = 0.0


func _get_move_input(delta: float) -> void:
	var vy = velocity.y
	velocity.y = 0
	var input = Input.get_vector("left","right","forward","back")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm_3d.rotation.y)
	velocity = lerp(velocity, dir * SPEED, ACCELERATION * delta)
	var vl = velocity * rig.transform.basis
	animation_tree.set('parameters/IWR/blend_position', Vector2(vl.x, -vl.z) / SPEED)
	velocity.y = vy

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		spring_arm_3d.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		spring_arm_3d.rotation_degrees.x = clamp(spring_arm_3d.rotation_degrees.x, -90.0, 30.0)
		spring_arm_3d.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
	if event.is_action_pressed("attack"):
		if not can_play_animation:
			return
		can_play_animation = false
		is_attacking = true
		has_hit_during_attack = false
		var chosen_attack = attacks.pick_random()
		animation_state.travel(chosen_attack)
		SoundManager.play_attack()
		await animation_tree.animation_finished
		is_attacking = false
		can_play_animation = true

func _on_FootstepTimer_timeout() -> void:
	SoundManager.play_step_wood()
	footstep_timer.start()

func die_now() -> void:
	emit_signal("die")
	queue_free()

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	regen_timer = 0.0
	_update_health_ui()
	if current_health <= 0:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for i in enemies:
			i.velocity.y = 0
		_handle_death()

func _update_health_ui() -> void:
	for i in range(max_health):
		var heart = health_ui.get_child(i)
		heart.texture = preload("res://Assets/Hearts_Red_1.png") if i < current_health else preload("res://Assets/Hearts_Red_5.png")

func _handle_death() -> void:
	animation_state.travel('Death_A')
	await get_tree().create_timer(0.8).timeout
	get_tree().paused = true
	$"../End".visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if has_hit_during_attack:
		return
	if is_attacking and body.is_in_group("enemies"):
		body.take_damage(1)
		has_hit_during_attack = true
