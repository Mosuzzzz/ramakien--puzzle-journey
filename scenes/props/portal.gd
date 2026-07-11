extends Area2D

const GameState := preload("res://scenes/game_state.gd")

@export_file("*.tscn") var target_scene: String
@export var target_spawn := Vector2.ZERO
@export var prompt_text := "กด E"
@export var interaction_size := Vector2(110, 60)

var _player: Node2D = null

@onready var _prompt: Label = $Prompt
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var rectangle := _collision.shape.duplicate() as RectangleShape2D
	rectangle.size = interaction_size
	_collision.shape = rectangle

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
		_prompt.global_position = _player.global_position + Vector2(-90, -68)

func _unhandled_input(event: InputEvent) -> void:
	if _player and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		GameState.next_spawn = target_spawn
		get_tree().change_scene_to_file.call_deferred(target_scene)
