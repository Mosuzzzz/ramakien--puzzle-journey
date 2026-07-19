extends Area2D

@export var speaker_name: String = ""
@export var lines: Array[String] = []
@export var prompt_text := "กด E เพื่อพูดคุย"
@export var interaction_size := Vector2(110, 60)
@export var prompt_offset := Vector2(-90, -80)
@export var quest_after: String = ""
@export var quest_after_detail: String = ""
@export var narration_after: Array[String] = []
@export var narration_after_title: String = ""

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
		_prompt.global_position = _player.global_position + prompt_offset
		_prompt.visible = not Dialogue.is_active

func _input(event: InputEvent) -> void:
	if not _player or Dialogue.is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_interact()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_interact()

func _interact() -> void:
	Dialogue.start(speaker_name, lines)
	if quest_after != "" or not narration_after.is_empty():
		Dialogue.finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	get_viewport().set_input_as_handled()

func _on_dialogue_finished() -> void:
	if quest_after != "":
		Quest.set_quest(quest_after, quest_after_detail)
	if not narration_after.is_empty():
		Dialogue.start_narration(narration_after, narration_after_title)
