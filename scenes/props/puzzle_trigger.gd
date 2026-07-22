extends Area2D

signal activated

@export var prompt_text := "กด E เพื่อสำรวจ"
@export var interaction_size := Vector2(110, 60)

var _player: Node2D = null

@onready var _prompt: Label = $Prompt
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var rectangle := _collision.shape.duplicate() as RectangleShape2D
	rectangle.size = interaction_size
	_collision.shape = rectangle
	input_event.connect(_on_input_event)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player = body
		_prompt.text = prompt_text
		_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_prompt.hide()


func _process(_delta: float) -> void:
	if _player:
		_prompt.global_position = _player.global_position + Vector2(-90, -80)
		_prompt.visible = not Dialogue.is_active


func _input(event: InputEvent) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_activate()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activate()


func _activate() -> void:
	activated.emit()
	get_viewport().set_input_as_handled()
