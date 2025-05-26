extends CharacterBody3D
signal die

@export var SPEED: float = 0.2
@export var SEPARATION_RADIUS: float = 0.3
@export var ATTACK_RADIUS: float = 0.2
@export var SEPARATION_STRENGTH: float = 2.0
@export var ROTATION_SPEED: float = 5.0
@export var base_attack_cooldown: float = 2.5

@export var STEP_INTERVAL: float = 0.5
@export var STEP_MIN_DIST: float = -5.0
@export var STEP_MAX_DIST: float = 15.0
@export var STEP_MIN_VOL: float = -30.0
@export var STEP_MAX_VOL: float = -10.0
@export var max_health: int = 1

var health: int
var last_attack_time: float = -9999.0
var attack_cooldown: float

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var footstep_timer: Timer = $FootstepTimer

var player: CharacterBody3D
var is_dead = false

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

	attack_cooldown = base_attack_cooldown + randf_range(0.2, 1.2)

	SPEED += randf_range(-0.05, 0.05)

	footstep_timer.one_shot = true
	footstep_timer.wait_time = STEP_INTERVAL + randf_range(-0.1, 0.2)
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)

	var p = get_tree().get_nodes_in_group("player")
	if p.size() > 0:
		player = p[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	velocity.y -= gravity * delta

	if not player:
		return

	var to_p = player.global_transform.origin - global_transform.origin
	var dist_p = to_p.length()
	var seek = to_p.normalized()
	var sep = Vector3.ZERO

	var is_attacking = animation_player.current_animation == "1H_Melee_Attack_Chop"
	var can_attack = dist_p <= ATTACK_RADIUS
	var can_move = dist_p > ATTACK_RADIUS and not is_attacking

	if can_move:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other == self:
				continue
			var off = global_transform.origin - other.global_transform.origin
			var d = off.length()
			if d < SEPARATION_RADIUS and d > 0:
				sep += off.normalized() * (1.0 - d / SEPARATION_RADIUS)

		var steer = (seek + sep * SEPARATION_STRENGTH).normalized()
		steer.x += randf_range(-0.05, 0.05)
		steer.z += randf_range(-0.05, 0.05)
		steer = steer.normalized()

		velocity.x = steer.x * SPEED
		velocity.z = steer.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

	# Animation control
	var flat = Vector2(velocity.x, velocity.z)
	if is_attacking:
		pass
	elif flat.length() > 0.05:
		animation_player.play("Running_A")
	else:
		animation_player.play("Idle")

	if flat.length() > 0.1 or can_attack:
		var target_y = atan2(to_p.x, to_p.z)
		var dd = wrapf(target_y - rotation.y, -PI, PI)
		rotate_y(dd * ROTATION_SPEED * delta)

	var is_walking = is_on_floor() and flat.length() > 0.1
	if is_walking and footstep_timer.is_stopped():
		footstep_timer.start()
	elif not is_walking and not footstep_timer.is_stopped():
		footstep_timer.stop()

	if can_attack and not is_attacking:
		await try_attack_player()

func try_attack_player() -> void:
	if not player:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time >= attack_cooldown:
		animation_player.play("1H_Melee_Attack_Chop")
		await animation_player.animation_finished
		if global_transform.origin.distance_to(player.global_transform.origin) <= ATTACK_RADIUS:
			if player.has_method("take_damage"):
				player.take_damage(1)
		last_attack_time = now

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die_now()

func die_now() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	animation_player.play("Death_A")
	await get_tree().create_timer(1.0).timeout
	emit_signal("die")
	queue_free()

func _on_footstep_timer_timeout() -> void:
	var d = global_transform.origin.distance_to(player.global_transform.origin)
	var t = 1.0 - clamp((d - STEP_MIN_DIST) / (STEP_MAX_DIST - STEP_MIN_DIST), 0.0, 1.0)
	var db = lerp(STEP_MIN_VOL, STEP_MAX_VOL, t)
	SoundManager.play_step_wood(db)
	footstep_timer.start()
