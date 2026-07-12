extends CharacterBody2D

@export var run_speed := 60.0
@export var patrol_distance := 70.0
@export var idle_duration := 0.8

const IDLE_POSITION := Vector2(0, -39)
const IDLE_SCALE := Vector2(0.075, 0.075)
const RUN_POSITION := Vector2(0, -51)
const RUN_SCALE := Vector2(0.64, 0.64)

var _start_x := 0.0
var _direction := 1.0
var _wait_time := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_start_x = position.x
	_show_idle()

func _physics_process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time = maxf(_wait_time - delta, 0.0)
		velocity = Vector2.ZERO
		_show_idle()
		return

	velocity = Vector2(_direction * run_speed, 0.0)
	move_and_slide()
	_show_run()

	if get_slide_collision_count() > 0 or absf(position.x - _start_x) >= patrol_distance:
		position.x = clampf(position.x, _start_x - patrol_distance, _start_x + patrol_distance)
		_direction *= -1.0
		_wait_time = idle_duration
		velocity = Vector2.ZERO
		_show_idle()

func _show_idle() -> void:
	animated_sprite.flip_h = _direction > 0.0
	_set_animation("idle")

func _show_run() -> void:
	animated_sprite.flip_h = _direction > 0.0
	_set_animation("run")

func _set_animation(animation_name: String) -> void:
	if animation_name == "run":
		animated_sprite.position = RUN_POSITION
		animated_sprite.scale = RUN_SCALE
	else:
		animated_sprite.position = IDLE_POSITION
		animated_sprite.scale = IDLE_SCALE
	if animated_sprite.animation != animation_name:
		animated_sprite.animation = animation_name
	animated_sprite.play()
