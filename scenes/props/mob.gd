extends CharacterBody2D

@export var speed: float = 60.0
@export var aggro_range: float = 220.0
@export var contact_damage: int = 10
@export var max_health: int = 30
@export var display_height: float = 60.0
@export var can_move: bool = true

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D

@onready var _sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	_sprite.animation = ""
	_play("idle")

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	if can_move:
		velocity = to_player.normalized() * speed if to_player.length() < aggro_range else Vector2.ZERO
		move_and_slide()
		if velocity.x != 0.0:
			_sprite.flip_h = velocity.x > 0.0
		_play("run" if velocity.length() > 0.0 else "idle")
	if to_player.length() < 26.0 and _hit_cooldown == 0.0 and _player.has_method("take_damage"):
		_player.take_damage(contact_damage)
		_hit_cooldown = 1.0

func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		var s := display_height / tex.get_height()
		_sprite.scale = Vector2(s, s)
	_sprite.play(anim)

func take_damage(amount: int) -> void:
	_health -= amount
	if _health <= 0:
		queue_free()
		return
	_sprite.modulate = Color(1, 0.15, 0.15)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.25)
