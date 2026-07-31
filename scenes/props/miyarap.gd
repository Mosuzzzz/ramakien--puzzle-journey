extends CharacterBody2D

const MobScene := preload("res://scenes/props/mob.tscn")
const WaveScene := preload("res://scenes/props/wave.tscn")

@export var max_health: int = 220
@export var contact_damage: int = 25
@export var attack_range: float = 90.0
@export var attack_cooldown: float = 2.8
@export var display_height: float = 130.0
# accumulated damage taken before he staggers into the stun pose
@export var stun_threshold: float = 60.0
# stop summoning while this many of his minions are still alive
@export var max_minions: int = 4

# ground-slam impact lands here in the trimmed 12-frame attack clip
const ATTACK_HIT_FRAME := 5
# spawn minions on the last frame of the 6-frame summon clip (s0,s4,s5,s6,s7,s8)
const SUMMON_SPAWN_FRAME := 5
# the attack/summon/stun sheets have more transparent padding around the body than idle,
# so they need extra scale to make the character read the same size on-screen
const ANIM_DISPLAY_SCALE := {"attack": 1.1, "summon": 1.03, "stun": 0.97}

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D
var _attacking := false
var _stunned := false
var _stagger_damage: float = 0.0
var _minions: Array = []
var _hit_flash_tween: Tween

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	_play("idle")

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _attacking:
		return
	if _stagger_damage >= stun_threshold:
		_start_stun()
		return
	if _player == null or _hit_cooldown > 0.0:
		return
	if not _is_on_screen():
		return
	# as soon as he's in frame: randomly waves or summon, every cooldown
	if randi() % 2 == 0 and _alive_minion_count() < max_minions:
		_start_summon()
	else:
		_start_attack()

func _alive_minion_count() -> int:
	_minions = _minions.filter(func(m): return is_instance_valid(m))
	return _minions.size()

func _is_on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return true
	var screen_size: Vector2 = get_viewport_rect().size / cam.zoom
	var cam_pos: Vector2 = cam.get_screen_center_position()
	var visible_rect := Rect2(cam_pos - screen_size / 2.0, screen_size)
	return visible_rect.has_point(global_position)

func _start_stun() -> void:
	_attacking = true
	_stunned = true
	_stagger_damage = 0.0
	# stun clip ends collapsed asleep, so: collapse (1.6s) -> hold (0.5s) ->
	# play back in reverse to get up (1.6s) = ~3.7s total
	_play("stun")
	await _sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	_sprite.play(&"stun", -1.0)
	await _sprite.animation_finished
	_stunned = false
	_attacking = false
	_play("idle")

func _start_summon() -> void:
	_attacking = true
	_hit_cooldown = attack_cooldown
	AudioManager.play_sfx(AudioManager.INVITE)
	_play("summon")
	while _sprite.animation == &"summon" and _sprite.frame < SUMMON_SPAWN_FRAME:
		await _sprite.frame_changed
	_spawn_minion(Vector2(-95, 10))
	_spawn_minion(Vector2(95, 10))
	await _sprite.animation_finished
	_attacking = false
	_play("idle")

func _spawn_minion(offset: Vector2) -> void:
	var minion := MobScene.instantiate()
	get_parent().add_child(minion)
	minion.global_position = global_position + offset
	_minions.append(minion)

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
	_play_slam_sound()
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		if (_player.global_position - global_position).length() <= attack_range + 20.0:
			_player.take_damage(contact_damage)
	_spawn_wave(Vector2.LEFT)
	_spawn_wave(Vector2.RIGHT)
	_play_wave_sound()
	await _sprite.animation_finished
	_attacking = false
	_play("idle")

func take_damage(amount: int) -> void:
	if _stunned:
		return  # immune while stunned
	AudioManager.play_sfx(AudioManager.ENEMY_HIT)
	_flash_hit()
	_health -= amount
	_stagger_damage += amount
	if _health <= 0:
		await get_tree().create_timer(0.12).timeout
		queue_free()


func _play_slam_sound() -> void:
	AudioManager.play_sfx(AudioManager.GIANT)


func _play_wave_sound() -> void:
	AudioManager.play_sfx(AudioManager.WAVE)

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
	# scale from THIS animation's own frame height — the sheets have
	# different resolutions (stun tiles are 107px vs idle's 298px);
	# set unconditionally so autoplay/editor state can't leave a stale scale
	var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
	var s: float = display_height * float(ANIM_DISPLAY_SCALE.get(anim, 1.0)) / tex.get_height()
	_sprite.scale = Vector2(s, s)
	_sprite.play(anim)
