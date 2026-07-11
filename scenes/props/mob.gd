extends CharacterBody2D

@export var speed: float = 60.0
@export var aggro_range: float = 220.0
@export var contact_damage: int = 10
@export var max_health: int = 30
@export var display_height: float = 60.0
@export var can_move: bool = true
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2
@export var attack_hit_padding: float = 20.0

# which way each sprite sheet faces natively; flip_h mirrors it when facing the other way
const ANIM_FACES_RIGHT := {"idle": false, "run": false, "walk": true, "attack": true}
# Attack cells include generous transparent effect space around the character.
const ANIM_DISPLAY_SCALE := {"walk": 0.88, "attack": 1.796}
# per-animation sprite offset that keeps the feet on the same baseline
const ANIM_SPRITE_Y := {"walk": -10.5, "attack": -35.0}
const ATTACK_HIT_FRAME := 4

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D
var _face_right := false
var _attacking := false
var _hit_flash_tween: Tween

@onready var _sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	_sprite.animation = ""
	_play("idle")

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _player == null or _attacking:
		return
	var to_player := _player.global_position - global_position
	if to_player.length() < attack_range and _hit_cooldown == 0.0:
		_start_attack()
		return
	if can_move:
		velocity = to_player.normalized() * speed if to_player.length() < aggro_range else Vector2.ZERO
		move_and_slide()
		if velocity.x != 0.0:
			_face_right = velocity.x > 0.0
		_play("walk" if velocity.length() > 0.0 else "idle")

func _start_attack() -> void:
	_attacking = true
	_hit_cooldown = attack_cooldown
	velocity = Vector2.ZERO
	_face_right = _player.global_position.x > global_position.x
	_play("attack")
	# Follow the actual animation frame so damage stays aligned if its FPS changes.
	while _sprite.animation == &"attack" and _sprite.frame < ATTACK_HIT_FRAME:
		await _sprite.frame_changed
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		if (_player.global_position - global_position).length() <= attack_range + attack_hit_padding:
			_player.take_damage(contact_damage)
	await _sprite.animation_finished
	_attacking = false

func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		var s: float = display_height * ANIM_DISPLAY_SCALE.get(anim, 1.0) / tex.get_height()
		_sprite.scale = Vector2(s, s)
		_sprite.position.y = ANIM_SPRITE_Y.get(anim, -14.0)
	_sprite.flip_h = _face_right != ANIM_FACES_RIGHT.get(anim, false)
	_sprite.play(anim)

func take_damage(amount: int) -> void:
	_flash_hit()
	_health -= amount
	if _health <= 0:
		await get_tree().create_timer(0.12).timeout
		queue_free()

func _flash_hit() -> void:
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	_sprite.modulate = Color(1, 0.15, 0.15)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_interval(0.08)
	_hit_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.18)
