extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

const GameState := preload("res://scenes/game_state.gd")

@export var character_name: String = "Phra Ram"
@export var speed: float = 150.0
@export var max_health: int = 100
@export var display_height: float = 48.0

var current_health: int = max_health

# horizontal offset (texture px) of the drawn character from the frame center,
# measured from the sprite sheets; used to keep the character centered when flipping
const CHAR_X_OFF := {"idle": 21.8, "walk": 1.4}
var _cx: float = 0.0

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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
		)

func _physics_process(_delta: float) -> void:
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
			animated_sprite.flip_h = dir.x > 0.0
	else:
		_play_animation("idle")
	# cancel the baked-in offset so the character stays centered over the origin
	animated_sprite.position.x = _cx if animated_sprite.flip_h else -_cx

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
