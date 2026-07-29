extends CharacterBody2D

const PotionPickup := preload("res://scenes/props/potion_pickup.tscn")

signal defeated(mob: CharacterBody2D)

@export var speed: float = 60.0
@export var aggro_range: float = 220.0
@export var contact_damage: int = 10
@export var max_health: int = 30
@export var display_height: float = 60.0
@export var can_move: bool = true
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2
@export var attack_hit_padding: float = 20.0
@export_range(0.0, 1.0) var potion_drop_chance: float = 0.3

# which way each sprite sheet faces natively; flip_h mirrors it when facing the other way
const ANIM_FACES_RIGHT := {"idle": false, "run": false, "walk": true, "attack": true}
# Attack cells include generous transparent effect space around the character.
const ANIM_DISPLAY_SCALE := {
	"walk": 0.88,
	"attack": 1.796,
	"Attack": 1.0,
	"Jump attack": 1.2,
}
# per-animation sprite offset that keeps the feet on the same baseline
const ANIM_SPRITE_Y := {"walk": -10.5, "attack": -35.0}
const ATTACK_HIT_FRAME := 4

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D
var _face_right := false
var _attacking := false
var _defeated := false
var _hit_flash_tween: Tween
var damage_gate: Node = null

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
	var attack_animation := _play("attack")
	var frame_count := _sprite.sprite_frames.get_frame_count(attack_animation)
	var hit_frame: int = mini(ATTACK_HIT_FRAME, frame_count - 1)
	# Follow the actual animation frame so damage stays aligned if its FPS changes.
	while _sprite.animation == attack_animation and _sprite.frame < hit_frame:
		await _sprite.frame_changed
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		if (_player.global_position - global_position).length() <= attack_range + attack_hit_padding:
			_player.take_damage(contact_damage)
	if _sprite.sprite_frames.get_animation_loop(attack_animation):
		await get_tree().create_timer(0.1).timeout
	else:
		await _sprite.animation_finished
	_attacking = false

func _animation_for(requested: StringName) -> StringName:
	if _sprite.sprite_frames.has_animation(requested):
		return requested
	if requested == &"walk" and _sprite.sprite_frames.has_animation(&"run"):
		return &"run"
	if requested == &"attack" and _sprite.sprite_frames.has_animation(&"Attack"):
		return &"Attack"
	return &"idle"

func _play(requested: StringName) -> StringName:
	var anim := _animation_for(requested)
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		if tex != null:
			var s: float = display_height * ANIM_DISPLAY_SCALE.get(anim, 1.0) / tex.get_height()
			_sprite.scale = Vector2(s, s)
		_sprite.position.y = ANIM_SPRITE_Y.get(anim, _sprite.position.y)
	_sprite.flip_h = _face_right != ANIM_FACES_RIGHT.get(anim, false)
	_sprite.play(anim)
	return anim

func take_damage(amount: int) -> void:
	if _defeated:
		return
	if is_instance_valid(damage_gate) and damage_gate.has_method("request_mob_damage"):
		damage_gate.request_mob_damage(self, amount)
		return
	apply_authorized_damage(amount)


func apply_authorized_damage(amount: int) -> void:
	if _defeated:
		return
	_flash_hit()
	_health -= amount
	if _health <= 0:
		_defeated = true
		defeated.emit(self)
		if randf() < potion_drop_chance:
			_drop_potion()
		await get_tree().create_timer(0.12).timeout
		if is_inside_tree():
			queue_free()


func _drop_potion() -> void:
	var pickup := PotionPickup.instantiate()
	pickup.global_position = global_position
	get_parent().add_child(pickup)


func would_damage_defeat(amount: int) -> bool:
	return not _defeated and _health - amount <= 0


func restore_full_health() -> void:
	_health = max_health
	_defeated = false


func _flash_hit() -> void:
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	_sprite.modulate = Color(1, 0.15, 0.15)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_interval(0.08)
	_hit_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.18)
