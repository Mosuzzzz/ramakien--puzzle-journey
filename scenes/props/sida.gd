extends CharacterBody2D

signal following_started

# once rescued, whether she actually walks after the player
@export var can_walk: bool = true
@export var speed: float = 120.0  # slower than the player (150)
@export var follow_distance: float = 45.0
# scale factor: character renders at display_height * (char_px / region_px)
@export var display_height: float = 59.4

var _following := false
var _player: Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_player = get_parent().get_node_or_null("Player")
	_play("idle")

func _physics_process(_delta: float) -> void:
	if _player == null:
		_update_run_audio(false)
		return
	# approaching Sida "rescues" her (fires the signal once, used by ch8/ch9
	# progression); once rescued, she walks behind the player
	if not _following:
		_update_run_audio(false)
		if _player.global_position.distance_to(global_position) < 60.0:
			start_following()
		return
	if not can_walk:
		_update_run_audio(false)
		return
	var to_player := _player.global_position - global_position
	if to_player.length() > follow_distance:
		velocity = to_player.normalized() * speed
		move_and_slide()
		_play("run")
		_update_run_audio(true)
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x > 0.0
	else:
		velocity = Vector2.ZERO
		_play("idle")
		_update_run_audio(false)


func start_following() -> void:
	if _following:
		return
	_following = true
	following_started.emit()


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		var s := display_height / tex.get_height()
		_sprite.scale = Vector2(s, s)
	_sprite.play(anim)


func _update_run_audio(active: bool) -> void:
	AudioManager.set_run_active(self, active)


func _exit_tree() -> void:
	AudioManager.set_run_active(self, false)
