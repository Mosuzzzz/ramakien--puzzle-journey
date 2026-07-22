extends CharacterBody2D

signal defeated
signal escaped

@export var flee_speed: float = 130.0
@export var flee_trigger_range: float = 170.0
@export var max_health: int = 45
@export var display_height: float = 66.0
# when set, a spooked deer runs to this spot (e.g. the forest gate) and holds
# there, instead of endlessly fleeing away from the player
@export var flee_target := Vector2.INF
# when true, the deer vanishes (escapes) once it reaches flee_target
@export var escape_on_arrival := false
# when true, arrows can't hurt it (the catch happens through story/quiz instead)
@export var invulnerable := false

var _health: int = max_health
var _player: Node2D
var _face_right := false
var _dead := false
var _spooked := false
var _hit_flash_tween: Tween

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	_play("idle")


func _physics_process(_delta: float) -> void:
	if _dead or _player == null:
		return
	var away := global_position - _player.global_position
	if not _spooked and away.length() < flee_trigger_range:
		_spooked = true

	if flee_target.is_finite() and _spooked:
		var to_target := flee_target - global_position
		# escaping deer only needs to reach the gate mouth, not the exact
		# (off-map) target point, which map-edge colliders may pinch off
		var arrive_distance := 100.0 if escape_on_arrival else 12.0
		if to_target.length() > arrive_distance:
			velocity = to_target.normalized() * flee_speed
			move_and_slide()
			if velocity.x != 0.0:
				_face_right = velocity.x > 0.0
			_play("run")
		elif escape_on_arrival:
			escaped.emit()
			queue_free()
		else:
			velocity = Vector2.ZERO
			_face_right = _player.global_position.x > global_position.x
			_play("idle")
		return

	if away.length() < flee_trigger_range:
		velocity = away.normalized() * flee_speed
		move_and_slide()
		if velocity.x != 0.0:
			_face_right = velocity.x > 0.0
		_play("run")
	else:
		velocity = Vector2.ZERO
		_play("idle")


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		var s := display_height / tex.get_height()
		_sprite.scale = Vector2(s, s)
	_sprite.flip_h = _face_right
	_sprite.play(anim)


func take_damage(amount: int) -> void:
	if _dead or not visible:
		return
	if invulnerable:
		_flash_hit()
		return
	_flash_hit()
	_health -= amount
	if _health <= 0:
		_die()


func _flash_hit() -> void:
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	_sprite.modulate = Color(1, 0.15, 0.15)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_interval(0.08)
	_hit_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.18)


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	hide()
	set_physics_process(false)
	# ponytail: no Maricha demon-form art exists yet; the transformation/death
	# is told through narration instead. Swap in real art + an animated
	# reveal here if that asset gets made.
	defeated.emit()
