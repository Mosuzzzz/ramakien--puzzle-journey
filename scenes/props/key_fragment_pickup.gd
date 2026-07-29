extends Area2D

signal collection_requested(pickup: Area2D)

@export var item_id := ""
@export var prompt_text := "กด E เพื่อเก็บชิ้นส่วนกุญแจ"
@export var texture: Texture2D
@export var display_size := 56.0
@export var bob_height := 6.0
@export var bob_speed := 3.0

var _elapsed := 0.0
var _player: CharacterBody2D
var _collected := false

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite
@onready var _prompt: Label = $Prompt


func configure(new_item_id: String, icon: Texture2D, new_prompt_text := "กด E เพื่อเก็บชิ้นส่วนกุญแจ") -> void:
	item_id = new_item_id
	texture = icon
	prompt_text = new_prompt_text


func _ready() -> void:
	_prompt.text = prompt_text
	_prompt.hide()
	_sprite.texture = texture
	if texture != null:
		var longest_side := maxf(texture.get_width(), texture.get_height())
		if longest_side > 0.0:
			var icon_scale := display_size / longest_side
			_sprite.scale = Vector2(icon_scale, icon_scale)


func _process(delta: float) -> void:
	_elapsed += delta
	_visual.position.y = sin(_elapsed * bob_speed) * bob_height


func _input(event: InputEvent) -> void:
	if _player == null or _collected:
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_collected = true
		_prompt.hide()
		monitoring = false
		collection_requested.emit(self)
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not _collected and body is CharacterBody2D and body.name == "Player":
		_player = body
		_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_prompt.hide()
