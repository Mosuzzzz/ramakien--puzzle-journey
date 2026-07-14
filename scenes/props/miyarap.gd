extends CharacterBody2D

const MobScene := preload("res://scenes/props/mob.tscn")
const WaveScene := preload("res://scenes/props/wave.tscn")

@export var max_health: int = 220
@export var contact_damage: int = 25
@export var attack_range: float = 90.0
@export var attack_cooldown: float = 1.6
@export var summon_range: float = 220.0
@export var display_height: float = 130.0

# ground-slam impact lands here in the trimmed 12-frame attack clip
const ATTACK_HIT_FRAME := 5
# spawn minions once the ghosts are fully formed (index of s9 in the
# ping-pong summon sequence: s0,s3,s4,s5,s6,s7,s8,s9,s8,s6,s5,s4,s3,s0)
const SUMMON_SPAWN_FRAME := 7
# the attack/summon sheets have more transparent padding around the body than idle,
# so they need extra scale to make the character read the same size on-screen
const ANIM_DISPLAY_SCALE := {"attack": 1.1, "summon": 1.03}

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D
var _attacking := false
var _has_summoned := false
var _hit_flash_tween: Tween

@onready var _sprite: AnimatedSprite2D = $Sprite

var _base_scale: float

func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	var idle_tex := _sprite.sprite_frames.get_frame_texture("idle", 0)
	_base_scale = display_height / idle_tex.get_height()
	_sprite.scale = Vector2(_base_scale, _base_scale)
	_play("idle")

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _player == null or _attacking:
		return
	var dist := (_player.global_position - global_position).length()
	if not _has_summoned and dist < summon_range:
		_start_summon()
		return
	if _hit_cooldown > 0.0:
		return
	if dist < attack_range:
		_start_attack()

func _start_summon() -> void:
	_attacking = true
	_has_summoned = true
	_play("summon")
	while _sprite.animation == &"summon" and _sprite.frame < SUMMON_SPAWN_FRAME:
		await _sprite.frame_changed
	_spawn_minion(Vector2(-95, 10))
	_spawn_minion(Vector2(95, 10))
	# summon loops, so cut to idle immediately or it'll loop back and replay the gesture
	_attacking = false
	_play("idle")

func _spawn_minion(offset: Vector2) -> void:
	var minion := MobScene.instantiate()
	get_parent().add_child(minion)
	minion.global_position = global_position + offset

func _spawn_wave(dir: Vector2) -> void:
	var wave := WaveScene.instantiate()
	wave.direction = dir
	wave.shooter = self
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(0, 10)

func _start_attack() -> void:
	_attacking = true
	_hit_cooldown = attack_cooldown
	_play("attack")
	while _sprite.animation == &"attack" and _sprite.frame < ATTACK_HIT_FRAME:
		await _sprite.frame_changed
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		if (_player.global_position - global_position).length() <= attack_range + 20.0:
			_player.take_damage(contact_damage)
	_spawn_wave(Vector2.LEFT)
	_spawn_wave(Vector2.RIGHT)
	await _sprite.animation_finished
	_attacking = false
	_play("idle")

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

func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
		var s: float = _base_scale * float(ANIM_DISPLAY_SCALE.get(anim, 1.0))
		_sprite.scale = Vector2(s, s)
	_sprite.play(anim)
