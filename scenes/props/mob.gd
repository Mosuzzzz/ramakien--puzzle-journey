extends CharacterBody2D

# ponytail: mock mob — placeholder visual (tinted Godot icon), chase + contact damage;
# swap the Sprite texture for real art when it exists
@export var speed: float = 60.0
@export var aggro_range: float = 220.0
@export var contact_damage: int = 10
@export var max_health: int = 30

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D

func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _player == null:
		return
	var to_player := _player.global_position - global_position
	velocity = to_player.normalized() * speed if to_player.length() < aggro_range else Vector2.ZERO
	move_and_slide()
	if to_player.length() < 26.0 and _hit_cooldown == 0.0 and _player.has_method("take_damage"):
		_player.take_damage(contact_damage)
		_hit_cooldown = 1.0

func take_damage(amount: int) -> void:
	_health -= amount
	if _health <= 0:
		queue_free()
		return
	$Sprite.modulate = Color(1, 0.15, 0.15)
	create_tween().tween_property($Sprite, "modulate", Color.WHITE, 0.25)
