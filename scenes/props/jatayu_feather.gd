class_name JatayuFeather
extends Area2D

signal collection_requested(feather: Area2D)

@export var bob_height := 7.0
@export var bob_speed := 2.4

var _elapsed := 0.0
var _player_nearby := false
var _interaction_enabled := true

@onready var _wing: Sprite2D = $Wing
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	_prompt.hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	_wing.position.y = sin(_elapsed * bob_speed) * bob_height


func _unhandled_input(event: InputEvent) -> void:
	if (
		_interaction_enabled
		and _player_nearby
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_E
	):
		_interaction_enabled = false
		_prompt.hide()
		collection_requested.emit(self)
		get_viewport().set_input_as_handled()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	monitoring = enabled
	_prompt.visible = enabled and _player_nearby and visible


func activate_at(new_position: Vector2) -> void:
	global_position = new_position
	_elapsed = 0.0
	_wing.position.y = 0.0
	modulate.a = 1.0
	show()
	set_interaction_enabled(true)


func fade_and_relocate(new_position: Vector2) -> void:
	set_interaction_enabled(false)
	var fade_out := create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(self, "modulate:a", 0.0, 0.45)
	await fade_out.finished
	global_position = new_position
	_elapsed = 0.0
	_wing.position.y = 0.0
	var fade_in := create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(self, "modulate:a", 1.0, 0.45)
	await fade_in.finished
	set_interaction_enabled(true)


func mark_collected() -> void:
	set_interaction_enabled(false)
	_player_nearby = false
	hide()


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_nearby = true
	_prompt.visible = _interaction_enabled and visible


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_nearby = false
	_prompt.hide()
