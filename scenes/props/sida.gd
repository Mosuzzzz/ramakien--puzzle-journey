extends CharacterBody2D

signal following_started

# scale factor: character renders at display_height * (char_px / region_px)
@export var display_height: float = 59.4

var _following := false
var _player: Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_player = get_parent().get_node_or_null("Player")
	_play("idle")

func _physics_process(_delta: float) -> void:
	# approaching Sida "rescues" her (fires the signal once, used by ch8/ch9
	# progression); she no longer walks after the player
	if _following or _player == null:
		return
	if _player.global_position.distance_to(global_position) < 60.0:
		start_following()


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
