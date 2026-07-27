class_name MagicTrail
extends Area2D

signal interaction_requested(trail: Area2D)
signal movement_finished
signal fade_finished

@export var bob_height := 7.0
@export var bob_speed := 2.4
@export var move_duration := 0.65
@export var fade_duration := 0.6

var _player_nearby := false
var _interaction_enabled := false
var _bob_time := 0.0
var _moving := false

@onready var _icon: Sprite2D = $Icon
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	monitoring = false
	_prompt.hide()
	hide()


func _process(delta: float) -> void:
	if not visible or _moving:
		return
	_bob_time += delta * bob_speed
	_icon.position.y = sin(_bob_time) * bob_height


func _unhandled_input(event: InputEvent) -> void:
	if not _interaction_enabled or not _player_nearby or Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		set_interaction_enabled(false)
		interaction_requested.emit(self)
		get_viewport().set_input_as_handled()


func activate_at(world_position: Vector2) -> void:
	global_position = world_position
	modulate.a = 1.0
	_icon.position = Vector2.ZERO
	_bob_time = 0.0
	monitoring = true
	show()
	set_interaction_enabled(true)


func move_to(world_position: Vector2) -> void:
	set_interaction_enabled(false)
	_moving = true
	_icon.position = Vector2.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", world_position, move_duration)
	await tween.finished
	_moving = false
	set_interaction_enabled(true)
	movement_finished.emit()


func fade_out() -> void:
	set_interaction_enabled(false)
	monitoring = false
	_moving = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	hide()
	_moving = false
	fade_finished.emit()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	_prompt.visible = enabled and _player_nearby


func is_interaction_enabled() -> bool:
	return _interaction_enabled


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player_nearby = true
		_prompt.visible = _interaction_enabled


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		_player_nearby = false
		_prompt.hide()
