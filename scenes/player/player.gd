extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

const GameState := preload("res://scenes/game_state.gd")
const ArrowScene := preload("res://scenes/props/arrow.tscn")

@export var character_name: String = "Phra Ram"
@export var speed: float = 150.0
@export var max_health: int = 100
@export var display_height: float = 60.0

var current_health: int = max_health

# horizontal offset (texture px) of the drawn character from the frame center,
# measured from the sprite sheets; used to keep the character centered when flipping
const CHAR_X_OFF := {"idle": 0.0, "walk": 0.0, "shoot": 0.0}
var _cx: float = 0.0
var _face_right := false
var _shooting := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	current_health = max_health
	if GameState.next_spawn.is_finite():
		global_position = GameState.next_spawn
		GameState.next_spawn = Vector2.INF
	camera.make_current()
	animated_sprite.animation = ""
	_play_animation("idle")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and not _shooting:
		_shoot()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
		)

func _physics_process(_delta: float) -> void:
	if _shooting:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	dir += Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

	if dir.length() > 0.0:
		_play_animation("walk")
		if dir.x != 0.0:
			_face_right = dir.x > 0.0
	else:
		_play_animation("idle")
	animated_sprite.flip_h = _face_right
	# cancel the baked-in offset so the character stays centered over the origin
	animated_sprite.position.x = _cx if animated_sprite.flip_h else -_cx

func _shoot() -> void:
	_shooting = true
	velocity = Vector2.ZERO
	_play_animation("shoot")
	# the shooting sheet faces right while the other sheets face left
	animated_sprite.flip_h = not _face_right
	# loose the arrow on the RELEASE frame (frame 5 of 8 at 12 fps)
	await get_tree().create_timer(4.0 / 12.0).timeout
	_spawn_arrow()
	await animated_sprite.animation_finished
	_shooting = false

func _spawn_arrow() -> void:
	var arrow := ArrowScene.instantiate()
	arrow.direction = Vector2.RIGHT if _face_right else Vector2.LEFT
	arrow.shooter = self
	arrow.global_position = global_position + Vector2(14.0 if _face_right else -14.0, -20.0)
	get_parent().add_child(arrow)

func _play_animation(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.animation = anim_name
		var tex := animated_sprite.sprite_frames.get_frame_texture(anim_name, 0)
		var s := display_height / tex.get_height()
		animated_sprite.scale = Vector2(s, s)
		_cx = CHAR_X_OFF.get(anim_name, 0.0) * s
	animated_sprite.play(anim_name)

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
