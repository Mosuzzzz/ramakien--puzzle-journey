extends "res://scenes/props/mob.gd"

@export var always_chase_player: bool = true

@export var normal_attacks_before_dash: int = 3
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.45
@export var dash_trigger_range: float = 300.0
@export var dash_hit_distance: float = 85.0
@export var dash_damage: int = 35
@export var dash_recovery_duration: float = 1.0
@export_range(0, 8, 1) var dash_start_frame: int = 5
@export var attacks_before_skill: int = 5
@export var skill_speed: float = 220.0
@export var skill_trigger_range: float = 450.0
@export var skill_hit_distance: float = 95.0
@export var skill_stop_distance: float = 55.0
@export var skill_damage_interval: float = 0.4
@export var random_special_delay: float = 6.0
@export var random_special_cooldown: float = 9.0
@export var random_special_range: float = 300.0
@export_range(0.05, 0.95, 0.05) var near_death_health_ratio: float = 0.3

var _normal_attack_count: int = 0
var _skill_attack_count: int = 0
var _dash_active := false
var _dash_time_left := 0.0
var _dash_direction := Vector2.ZERO
var _dash_damage_done := false
var _dash_has_started := false
var _dash_recovery_time_left := 0.0
var _skill_active := false
var _skill_damage_cooldown := 0.0
var _combat_time := 0.0
var _time_since_attack := 0.0
var _random_special_cooldown_left := 0.0
var _initial_player_health := -1
var _player_hp_has_dropped := false
var _near_death_special_used := false


func _ready() -> void:
	if always_chase_player:
		aggro_range = INF
	super._ready()
	if not _sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		_sprite.animation_finished.connect(_on_sprite_animation_finished)
	if is_instance_valid(_player):
		var health_value: Variant = _player.get("current_health")
		if health_value != null:
			_initial_player_health = int(health_value)


func _physics_process(delta: float) -> void:
	_combat_time += delta
	_time_since_attack += delta
	_random_special_cooldown_left = maxf(_random_special_cooldown_left - delta, 0.0)
	_update_player_damage_state()

	if _skill_active:
		_process_skill(delta)
		return

	if _dash_active:
		_process_dash(delta)
		return

	if _dash_recovery_time_left > 0.0:
		_process_dash_recovery(delta)
		return

	if _should_use_random_special():
		_begin_random_special()
		return

	if (
		is_instance_valid(_player)
		and not _attacking
		and _skill_attack_count >= attacks_before_skill
		and _hit_cooldown <= 0.0
		and (_player.global_position - global_position).length() <= skill_trigger_range
	):
		_begin_skill()
		return

	if (
		is_instance_valid(_player)
		and not _attacking
		and _normal_attack_count >= normal_attacks_before_dash
		and _hit_cooldown <= 0.0
		and (_player.global_position - global_position).length() <= dash_trigger_range
	):
		_begin_dash_attack()
		return

	super._physics_process(delta)


func _start_attack() -> void:
	_time_since_attack = 0.0
	await super._start_attack()
	_normal_attack_count = mini(_normal_attack_count + 1, normal_attacks_before_dash)
	_skill_attack_count = mini(_skill_attack_count + 1, attacks_before_skill)


func _begin_dash_attack() -> void:
	_time_since_attack = 0.0
	_attacking = true
	_dash_active = true
	_dash_time_left = dash_duration
	_dash_damage_done = false
	_dash_has_started = false
	_normal_attack_count = 0
	_dash_direction = Vector2.ZERO
	_face_right = _player.global_position.x > global_position.x
	if (
		_sprite.sprite_frames.has_animation(&"DashAttack")
		and _sprite.sprite_frames.get_frame_count(&"DashAttack") > 0
	):
		_play("DashAttack")
		_sprite.speed_scale = 1.0
	else:
		_play("attack")
		_start_dash_movement()


func _start_dash_movement() -> void:
	_dash_has_started = true
	_dash_time_left = dash_duration
	if is_instance_valid(_player):
		_dash_direction = (_player.global_position - global_position).normalized()
		_face_right = _dash_direction.x > 0.0
		_sprite.flip_h = _face_right != ANIM_FACES_RIGHT.get(_sprite.animation, false)
	_fit_dash_animation_to_duration()


func _fit_dash_animation_to_duration() -> void:
	var frame_count: int = _sprite.sprite_frames.get_frame_count(&"DashAttack")
	var animation_fps: float = _sprite.sprite_frames.get_animation_speed(&"DashAttack")
	if frame_count <= 0 or animation_fps <= 0.0 or dash_duration <= 0.0:
		return
	var animation_duration := 0.0
	var first_dash_frame: int = clampi(dash_start_frame, 0, frame_count - 1)
	for frame_index in range(first_dash_frame, frame_count):
		animation_duration += (
			_sprite.sprite_frames.get_frame_duration(&"DashAttack", frame_index) / animation_fps
		)
	_sprite.speed_scale = animation_duration / dash_duration


func _process_dash(delta: float) -> void:
	if not _dash_has_started:
		velocity = Vector2.ZERO
		if _sprite.animation == &"DashAttack" and _sprite.frame < dash_start_frame:
			return
		_start_dash_movement()

	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	velocity = _dash_direction * dash_speed
	move_and_slide()

	if (
		not _dash_damage_done
		and is_instance_valid(_player)
		and (_player.global_position - global_position).length() <= dash_hit_distance
	):
		_player.take_damage(dash_damage)
		_dash_damage_done = true

	if _dash_time_left <= 0.0:
		_finish_dash_attack()

func _finish_dash_attack() -> void:
	velocity = Vector2.ZERO
	_dash_active = false
	_dash_recovery_time_left = dash_recovery_duration
	_sprite.speed_scale = 1.0
	_play("idle")


func _process_dash_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	_dash_recovery_time_left = maxf(_dash_recovery_time_left - delta, 0.0)
	if _dash_recovery_time_left <= 0.0:
		_attacking = false
		_hit_cooldown = attack_cooldown


func _begin_skill() -> void:
	_time_since_attack = 0.0
	_attacking = true
	_skill_active = true
	_skill_damage_cooldown = 0.0
	_skill_attack_count = 0
	_play("Skill")


func _process_skill(delta: float) -> void:
	if not is_instance_valid(_player):
		_finish_skill()
		return

	_skill_damage_cooldown = maxf(_skill_damage_cooldown - delta, 0.0)
	var to_player: Vector2 = _player.global_position - global_position
	var distance_to_player: float = to_player.length()
	if distance_to_player > skill_stop_distance:
		var direction: Vector2 = to_player / distance_to_player
		_face_right = direction.x > 0.0
		_sprite.flip_h = _face_right != ANIM_FACES_RIGHT.get(&"Skill", false)
		velocity = direction * skill_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	if distance_to_player <= skill_hit_distance and _skill_damage_cooldown <= 0.0:
		var damage: int = maxi(1, roundi(float(contact_damage) * 0.25))
		_player.take_damage(damage)
		_skill_damage_cooldown = skill_damage_interval


func _on_sprite_animation_finished() -> void:
	if _skill_active and _sprite.animation == &"Skill":
		_finish_skill()

func _finish_skill() -> void:
	velocity = Vector2.ZERO
	_skill_active = false
	_attacking = false
	_hit_cooldown = attack_cooldown
	_play("idle")


func _update_player_damage_state() -> void:
	if _player_hp_has_dropped or not is_instance_valid(_player) or _initial_player_health < 0:
		return
	var health_value: Variant = _player.get("current_health")
	if health_value != null and int(health_value) < _initial_player_health:
		_player_hp_has_dropped = true


func _is_near_death() -> bool:
	return max_health > 0 and float(_health) / float(max_health) <= near_death_health_ratio


func _should_use_random_special() -> bool:
	if not is_instance_valid(_player) or _attacking or _random_special_cooldown_left > 0.0:
		return false
	if (_player.global_position - global_position).length() > random_special_range:
		return false
	var has_not_attacked := _time_since_attack >= random_special_delay
	var player_is_untouched := not _player_hp_has_dropped and _combat_time >= random_special_delay
	var near_death_ready := _is_near_death() and not _near_death_special_used
	return has_not_attacked or player_is_untouched or near_death_ready


func _begin_random_special() -> void:
	if _is_near_death():
		_near_death_special_used = true
	_random_special_cooldown_left = random_special_cooldown
	_time_since_attack = 0.0
	if randi_range(0, 1) == 0:
		_begin_dash_attack()
	else:
		_begin_skill()
