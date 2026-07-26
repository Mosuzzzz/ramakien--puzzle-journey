extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

const GameState := preload("res://scenes/core/game_state.gd")
const MeleeHitScene := preload("res://scenes/props/melee_hit.tscn")

@export var character_name: String = "Hanuman"
@export var speed: float = 160.0
@export var dash_speed: float = 480.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.55
@export var max_health: int = 100
@export var display_height: float = 60.0
@export var potion_heal: int = 30
@export var attack_damage: int = 20
# frame index (0-based) of the attack clip where the mace lands
@export var attack_hit_frame: int = 1
@export var attack_cooldown: float = 0.6

# the idle/walk/attack sheets crop the character to very different amounts of
# padding, so a raw height-based scale makes him a different size per animation;
# these compensate so he reads as the same size in all three
const ANIM_DISPLAY_SCALE := {"walk": 1.53, "attack": 0.89}

var current_health: int = max_health

# fractions of the player_bar texture width where the red pill begins/ends
# (the gold flame ends take up the rest)
const BAR_FILL_START := 0.027
const BAR_FILL_END := 0.97

var _face_right := false
var _attacking := false
var _dash_direction := Vector2.LEFT
var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _attack_cooldown_left := 0.0
var _knockback_velocity := Vector2.ZERO
var _hit_flash_tween: Tween
var _dead := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var _health_bar: TextureProgressBar = $HUD/HealthBar
@onready var _hp_label: Label = $HUD/HPLabel
@onready var _potion_count: Label = $HUD/PotionCount

func _ready() -> void:
	current_health = max_health
	_update_health_bar()
	_update_hp_label()
	_update_potion_label()
	Inv.changed.connect(_update_potion_label)
	PauseMenu.set_hud_visible(true)
	Inv.set_hud_visible(true)
	Quest.set_hud_visible(true)
	if GameState.next_spawn.is_finite():
		global_position = GameState.next_spawn
		GameState.next_spawn = Vector2.INF
	_configure_camera_for_map()
	camera.make_current()
	animated_sprite.animation = ""
	_play_animation("idle")

func _configure_camera_for_map() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return

	var background := scene.find_child("Background", true, false) as Sprite2D
	if background == null or background.texture == null:
		return

	var rect: Rect2 = background.get_rect()
	var corners: Array[Vector2] = [
		background.to_global(rect.position),
		background.to_global(rect.position + Vector2(rect.size.x, 0.0)),
		background.to_global(rect.position + Vector2(0.0, rect.size.y)),
		background.to_global(rect.position + rect.size),
	]

	var min_pos: Vector2 = corners[0]
	var max_pos: Vector2 = corners[0]
	for corner: Vector2 in corners:
		min_pos.x = minf(min_pos.x, corner.x)
		min_pos.y = minf(min_pos.y, corner.y)
		max_pos.x = maxf(max_pos.x, corner.x)
		max_pos.y = maxf(max_pos.y, corner.y)

	camera.limit_left = floori(min_pos.x)
	camera.limit_top = floori(min_pos.y)
	camera.limit_right = ceili(max_pos.x)
	camera.limit_bottom = ceili(max_pos.y)

	var map_size: Vector2 = max_pos - min_pos
	var viewport_size: Vector2 = get_viewport_rect().size
	var minimum_zoom: float = maxf(
		viewport_size.x / maxf(map_size.x, 1.0),
		viewport_size.y / maxf(map_size.y, 1.0)
	)
	var zoom_value: float = maxf(maxf(camera.zoom.x, camera.zoom.y), minimum_zoom)
	camera.zoom = Vector2(zoom_value, zoom_value)

func _input(event: InputEvent) -> void:
	if Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and not _attacking and _attack_cooldown_left <= 0.0:
		_attack()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q and not _attacking:
		_start_dash()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
		_use_potion()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		Settings.toggle_fullscreen()
		call_deferred("_configure_camera_for_map")

func _physics_process(_delta: float) -> void:
	if _attacking:
		return
	if Dialogue.is_active:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_animation("idle")
		return
	_dash_cooldown_left = maxf(_dash_cooldown_left - _delta, 0.0)
	_attack_cooldown_left = maxf(_attack_cooldown_left - _delta, 0.0)
	if _knockback_velocity.length() > 4.0:
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 1100.0 * _delta)
		move_and_slide()
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	dir += Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if _dash_time_left > 0.0:
		_dash_time_left = maxf(_dash_time_left - _delta, 0.0)
		velocity = _dash_direction * dash_speed
	else:
		velocity = dir * speed
	move_and_slide()

	if _dash_time_left > 0.0 or dir.length() > 0.0:
		_play_animation("walk")
		var facing_direction := _dash_direction if _dash_time_left > 0.0 else dir
		if facing_direction.x != 0.0:
			_face_right = facing_direction.x > 0.0
	else:
		_play_animation("idle")
	# idle/walk art faces left natively, so flip to face right
	animated_sprite.flip_h = _face_right

func _start_dash() -> void:
	if _dash_cooldown_left > 0.0:
		return

	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_direction += Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	_dash_direction = input_direction.normalized() if input_direction.length() > 0.0 else (Vector2.RIGHT if _face_right else Vector2.LEFT)
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown

func _attack() -> void:
	_attacking = true
	_attack_cooldown_left = attack_cooldown
	_dash_time_left = 0.0
	velocity = Vector2.ZERO
	_play_animation("attack")
	# the attack sheet faces right while the idle/walk sheets face left
	animated_sprite.flip_h = not _face_right
	while animated_sprite.animation == "attack" and animated_sprite.frame < attack_hit_frame:
		await animated_sprite.frame_changed
	_melee_hit()
	await animated_sprite.animation_finished
	_attacking = false

func _melee_hit() -> void:
	var hit := MeleeHitScene.instantiate()
	hit.damage = attack_damage
	hit.shooter = self
	hit.global_position = global_position + Vector2(30.0 if _face_right else -30.0, -20.0)
	get_parent().add_child(hit)

func _play_animation(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.animation = anim_name
		var tex := animated_sprite.sprite_frames.get_frame_texture(anim_name, 0)
		var s: float = display_height * ANIM_DISPLAY_SCALE.get(anim_name, 1.0) / tex.get_height()
		animated_sprite.scale = Vector2(s, s)
	animated_sprite.play(anim_name)

func apply_knockback(dir: Vector2, force: float) -> void:
	if _dash_time_left > 0.0:
		return  # dash dodges the shove along with the damage
	if dir.length() > 0.0:
		_knockback_velocity = dir.normalized() * force

func take_damage(amount: int) -> void:
	if _dead:
		return
	if _dash_time_left > 0.0:
		return  # i-frames: dashing dodges all damage
	current_health = clampi(current_health - amount, 0, max_health)
	_update_health_bar()
	_update_hp_label()
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	animated_sprite.modulate = Color(1, 0.2, 0.2)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
		_die()

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	_update_health_bar()
	_update_hp_label()
	health_changed.emit(current_health, max_health)

func _update_health_bar() -> void:
	var frac := float(current_health) / float(max_health)
	_health_bar.value = _health_bar.max_value * lerpf(BAR_FILL_START, BAR_FILL_END, frac)

func _update_hp_label() -> void:
	_hp_label.text = "HP %d/%d" % [current_health, max_health]

func _use_potion() -> void:
	if _dead or current_health >= max_health:
		return
	if Inv.remove_item("potion"):
		heal(potion_heal)

func _update_potion_label() -> void:
	_potion_count.text = str(Inv.count("potion"))

func _die() -> void:
	_dead = true
	_attacking = true  # reuses the input lock so the body stays put while fading
	velocity = Vector2.ZERO
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	var fade := create_tween()
	fade.tween_property(animated_sprite, "modulate", Color(1, 0.2, 0.2, 0.0), 0.7)
	await fade.finished
	GameState.next_spawn = Vector2.INF
	get_tree().reload_current_scene()
