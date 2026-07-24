extends CharacterBody2D

signal following_started

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
		return
	var to_player := _player.global_position - global_position
	if not _following and to_player.length() < 60.0:
		start_following()
	if _following and to_player.length() > follow_distance:
		velocity = to_player.normalized() * speed
		move_and_slide()
		_play("run")
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x > 0.0
	else:
		velocity = Vector2.ZERO
		_play("idle")


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
