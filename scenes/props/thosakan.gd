extends "res://scenes/props/mob.gd"

@export var always_chase_player: bool = true

@export var normal_attacks_before_jump: int = 3
@export var jump_speed: float = 520.0
@export var jump_trigger_range: float = 300.0
@export var jump_hit_distance: float = 85.0
@export var jump_damage: int = 35
@export var jump_recovery_duration: float = 1.0
@export var pull_speed: float = 260.0
@export var pull_arrival_distance: float = 75.0
@export var pull_attack_damage: int = 40
@export_range(0.1, 1.0, 0.05) var pull_charge_speed_scale: float = 0.5
@export var inactivity_special_delay: float = 6.0
@export var inactivity_special_cooldown: float = 9.0
@export_range(0.05, 0.95, 0.05) var skill_trigger_health_ratio: float = 0.2
@export_range(0.05, 1.0, 0.05) var skill_restore_health_ratio: float = 0.6

const JUMP_ANIMATION := &"Jump attack"
const PULL_ANIMATION_LOWER := &"pull attack"
const PULL_ANIMATION_TITLE := &"Pull attack"
const SKILL_ANIMATION := &"Skill"
const JUMP_HOLD_FRAME := 3
const JUMP_IMPACT_FRAME := 4
const PULL_CHARGE_END_FRAME := 6
const PULL_FINISH_START_FRAME := 7

var _normal_attack_count: int = 0
var _jump_active := false
var _jump_approaching := false
var _jump_impact := false
var _jump_damage_done := false
var _jump_recovery_time_left := 0.0
var _jump_reference_visible_height := 0.0
var _jump_frame_scales: Dictionary[int, float] = {}
var _pull_active := false
var _pull_charging := false
var _pull_finishing := false
var _pull_animation_done := false
var _pull_damage_done := false
var _pull_animation: StringName = PULL_ANIMATION_LOWER
var _pull_original_player_speed := -1.0
var _boss_health_stale_time := 0.0
var _player_health_stale_time := 0.0
var _inactivity_special_cooldown_left := 0.0
var _last_player_health := -1
var _skill_active := false
var _skill_used := false


func _ready() -> void:
	if always_chase_player:
		aggro_range = INF
	super._ready()
	if not _sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		_sprite.animation_finished.connect(_on_sprite_animation_finished)
	if not _sprite.animation_looped.is_connected(_on_sprite_animation_looped):
		_sprite.animation_looped.connect(_on_sprite_animation_looped)
	if not _sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
	if is_instance_valid(_player):
		var player_health: Variant = _player.get("current_health")
		if player_health != null:
			_last_player_health = int(player_health)


func _physics_process(delta: float) -> void:
	_update_inactivity_timers(delta)

	if _skill_active:
		velocity = Vector2.ZERO
		return

	if _jump_active:
		_process_jump_attack()
		return

	if _pull_active:
		_process_pull_attack(delta)
		return

	if _jump_recovery_time_left > 0.0:
		_process_jump_recovery(delta)
		return

	if _should_use_inactivity_special():
		_trigger_inactivity_special()
		return

	if (
		is_instance_valid(_player)
		and not _attacking
		and _normal_attack_count >= normal_attacks_before_jump
		and _hit_cooldown <= 0.0
		and (_player.global_position - global_position).length() <= jump_trigger_range
	):
		_begin_random_special_attack()
		return

	super._physics_process(delta)


func _start_attack() -> void:
	await super._start_attack()
	_normal_attack_count = mini(_normal_attack_count + 1, normal_attacks_before_jump)


func take_damage(amount: int) -> void:
	if amount <= 0 or _health <= 0:
		return
	_flash_hit()
	_health = maxi(_health - amount, 0)
	_boss_health_stale_time = 0.0

	# This is a one-time second phase. It also saves Thosakan if one hit crosses
	# directly from above 20% to zero health.
	if not _skill_used and float(_health) / float(maxi(max_health, 1)) <= skill_trigger_health_ratio:
		_begin_heal_skill()
		return

	if _health <= 0:
		await get_tree().create_timer(0.12).timeout
		queue_free()


func _begin_heal_skill() -> void:
	if _pull_active and not _pull_damage_done:
		_set_player_pull_color(false)
	_restore_player_speed_after_pull_charge()
	_skill_used = true
	_skill_active = true
	_attacking = true
	_jump_active = false
	_jump_approaching = false
	_jump_impact = false
	_pull_active = false
	_pull_charging = false
	_pull_finishing = false
	_pull_animation_done = false
	_jump_recovery_time_left = 0.0
	velocity = Vector2.ZERO
	_health = clampi(roundi(float(max_health) * skill_restore_health_ratio), 1, max_health)
	_play(SKILL_ANIMATION)
	_sprite.speed_scale = 1.0


func _begin_random_special_attack() -> void:
	var has_lower := _sprite.sprite_frames.has_animation(PULL_ANIMATION_LOWER)
	var has_title := _sprite.sprite_frames.has_animation(PULL_ANIMATION_TITLE)
	if (has_lower or has_title) and randi_range(0, 1) == 0:
		_pull_animation = PULL_ANIMATION_LOWER if has_lower else PULL_ANIMATION_TITLE
		_begin_pull_attack()
	else:
		_begin_jump_attack()


func _update_inactivity_timers(delta: float) -> void:
	_boss_health_stale_time += delta
	_player_health_stale_time += delta
	_inactivity_special_cooldown_left = maxf(
		_inactivity_special_cooldown_left - delta, 0.0
	)
	if not is_instance_valid(_player):
		return
	var player_health: Variant = _player.get("current_health")
	if player_health == null:
		return
	var current_player_health := int(player_health)
	if _last_player_health < 0:
		_last_player_health = current_player_health
	elif current_player_health < _last_player_health:
		_player_health_stale_time = 0.0
	_last_player_health = current_player_health


func _should_use_inactivity_special() -> bool:
	if not is_instance_valid(_player) or _attacking:
		return false
	if _inactivity_special_cooldown_left > 0.0:
		return false
	if (_player.global_position - global_position).length() > jump_trigger_range:
		return false
	return (
		_boss_health_stale_time >= inactivity_special_delay
		or _player_health_stale_time >= inactivity_special_delay
	)


func _trigger_inactivity_special() -> void:
	_boss_health_stale_time = 0.0
	_player_health_stale_time = 0.0
	_inactivity_special_cooldown_left = inactivity_special_cooldown
	_begin_random_special_attack()


func _begin_pull_attack() -> void:
	_attacking = true
	_pull_active = true
	_pull_charging = true
	_pull_finishing = false
	_pull_animation_done = false
	_pull_damage_done = false
	_normal_attack_count = 0
	velocity = Vector2.ZERO
	if is_instance_valid(_player):
		_face_right = _player.global_position.x > global_position.x
		_set_player_pull_color(true)
		_slow_player_during_pull_charge()
	_play(_pull_animation)
	_sprite.speed_scale = pull_charge_speed_scale


func _process_pull_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(_player):
		_finish_pull_attack()
		return

	if _pull_charging:
		if _sprite.frame >= PULL_CHARGE_END_FRAME:
			_hold_pull_charge_frame()
		return
	var to_boss: Vector2 = global_position - _player.global_position
	if to_boss.length() > pull_arrival_distance:
		_player.global_position = _player.global_position.move_toward(
			global_position, pull_speed * delta
		)
		return

	_complete_pull_hit()


func _hold_pull_charge_frame() -> void:
	_pull_charging = false
	_pull_finishing = true
	_restore_player_speed_after_pull_charge()
	_sprite.speed_scale = 1.0
	_sprite.play(_pull_animation)
	_sprite.frame = PULL_FINISH_START_FRAME
	_sprite.frame_progress = 0.0


func _complete_pull_hit() -> void:
	if not _pull_damage_done and is_instance_valid(_player) and _player.has_method("take_damage"):
		_set_player_pull_color(false)
		_player.take_damage(pull_attack_damage)
		_pull_damage_done = true
	if _pull_animation_done:
		_finish_pull_attack()


func _set_player_pull_color(controlled: bool) -> void:
	if not is_instance_valid(_player):
		return
	var player_sprite := _player.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if player_sprite != null:
		player_sprite.modulate = Color(0.25, 1.0, 0.35) if controlled else Color.WHITE


func _slow_player_during_pull_charge() -> void:
	if not is_instance_valid(_player) or _pull_original_player_speed >= 0.0:
		return
	var speed_value: Variant = _player.get("speed")
	if speed_value != null:
		_pull_original_player_speed = float(speed_value)
		_player.set("speed", _pull_original_player_speed * 0.5)


func _restore_player_speed_after_pull_charge() -> void:
	if _pull_original_player_speed < 0.0:
		return
	if is_instance_valid(_player):
		_player.set("speed", _pull_original_player_speed)
	_pull_original_player_speed = -1.0


func _finish_pull_attack() -> void:
	_restore_player_speed_after_pull_charge()
	if not _pull_damage_done:
		_set_player_pull_color(false)
	_pull_active = false
	_pull_charging = false
	_pull_finishing = false
	_pull_animation_done = false
	_attacking = false
	_hit_cooldown = attack_cooldown
	_sprite.speed_scale = 1.0
	_play(&"idle")


func _finish_heal_skill() -> void:
	_skill_active = false
	_attacking = false
	_hit_cooldown = attack_cooldown
	_play(&"idle")


func _begin_jump_attack() -> void:
	_attacking = true
	_jump_active = true
	_jump_approaching = false
	_jump_impact = false
	_jump_damage_done = false
	_normal_attack_count = 0
	velocity = Vector2.ZERO
	_face_right = _player.global_position.x > global_position.x
	_play(JUMP_ANIMATION)
	_sprite.speed_scale = 1.0
	_jump_reference_visible_height = 0.0
	_jump_frame_scales.clear()
	_balance_jump_frame_scale()


func _process_jump_attack() -> void:
	if not is_instance_valid(_player):
		_finish_jump_attack()
		return

	if _jump_impact:
		velocity = Vector2.ZERO
		return

	# Frames 0-3 are the take-off. Freeze frame 3 while travelling.
	if not _jump_approaching:
		velocity = Vector2.ZERO
		if _sprite.frame < JUMP_HOLD_FRAME:
			return
		_jump_approaching = true
		_sprite.pause()
		_sprite.frame = JUMP_HOLD_FRAME

	var to_player := _player.global_position - global_position
	if to_player.length() > jump_hit_distance:
		var direction := to_player.normalized()
		_face_right = direction.x > 0.0
		_sprite.flip_h = _face_right != ANIM_FACES_RIGHT.get(JUMP_ANIMATION, false)
		velocity = direction * jump_speed
		move_and_slide()
		return

	_begin_jump_impact()


func _begin_jump_impact() -> void:
	_jump_impact = true
	velocity = Vector2.ZERO
	_sprite.play(JUMP_ANIMATION)
	_sprite.frame = JUMP_IMPACT_FRAME
	_sprite.frame_progress = 0.0
	if not _jump_damage_done and is_instance_valid(_player):
		_player.take_damage(jump_damage)
		_jump_damage_done = true


func _on_sprite_animation_finished() -> void:
	if _skill_active and _sprite.animation == SKILL_ANIMATION:
		_finish_heal_skill()
	elif _jump_active and _jump_impact and _sprite.animation == JUMP_ANIMATION:
		_finish_jump_attack()
	elif _pull_active and _sprite.animation == _pull_animation:
		_finish_pull_attack()


func _on_sprite_animation_looped() -> void:
	# The imported Pull animation is looped. Stop on its last frame after 7-10,
	# then wait only if the player has not reached Thosakan yet.
	if _pull_active and _pull_finishing and _sprite.animation == _pull_animation:
		_pull_animation_done = true
		_sprite.pause()
		_sprite.frame = _sprite.sprite_frames.get_frame_count(_pull_animation) - 1
		if _pull_damage_done:
			_finish_pull_attack()


func _on_sprite_frame_changed() -> void:
	if _sprite.animation == JUMP_ANIMATION:
		_balance_jump_frame_scale()
	elif _pull_active and _sprite.animation == _pull_animation:
		if _pull_charging and _sprite.frame >= PULL_CHARGE_END_FRAME:
			_hold_pull_charge_frame()


func _balance_jump_frame_scale() -> void:
	var frame_index := _sprite.frame
	if _jump_frame_scales.has(frame_index):
		var cached_scale: float = _jump_frame_scales[frame_index]
		_sprite.scale = Vector2(cached_scale, cached_scale)
		return

	var texture := _sprite.sprite_frames.get_frame_texture(JUMP_ANIMATION, frame_index)
	if texture == null:
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		return
	var visible_rect := image.get_used_rect()
	if visible_rect.size.y <= 0:
		return

	# Keep frame 0 at its designed size and normalize every following frame to
	# the same visible (non-transparent) height.
	if _jump_reference_visible_height <= 0.0:
		_jump_reference_visible_height = float(visible_rect.size.y) * _sprite.scale.y
	var balanced_scale := _jump_reference_visible_height / float(visible_rect.size.y)
	_jump_frame_scales[frame_index] = balanced_scale
	_sprite.scale = Vector2(balanced_scale, balanced_scale)


func _finish_jump_attack() -> void:
	velocity = Vector2.ZERO
	_jump_active = false
	_jump_approaching = false
	_jump_impact = false
	_jump_recovery_time_left = jump_recovery_duration
	_sprite.speed_scale = 1.0
	_play(&"idle")


func _process_jump_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	_jump_recovery_time_left = maxf(_jump_recovery_time_left - delta, 0.0)
	if _jump_recovery_time_left <= 0.0:
		_attacking = false
		_hit_cooldown = attack_cooldown
