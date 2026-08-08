extends Control

@onready var _player: Node2D = owner as Node2D
@onready var _clip: Control = $MapClip
@onready var _map_texture: TextureRect = $MapClip/MapTexture
@onready var _dot: Control = $MapClip/PlayerDot

var _min_pos := Vector2.ZERO
var _max_pos := Vector2.ONE
var _tracking := false

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return
	var background := scene.find_child("Background", true, false) as Sprite2D
	if background == null or background.texture == null:
		hide()
		return
	_map_texture.texture = background.texture
	var rect: Rect2 = background.get_rect()
	var corners: Array[Vector2] = [
		background.to_global(rect.position),
		background.to_global(rect.position + Vector2(rect.size.x, 0.0)),
		background.to_global(rect.position + Vector2(0.0, rect.size.y)),
		background.to_global(rect.position + rect.size),
	]
	_min_pos = corners[0]
	_max_pos = corners[0]
	for corner: Vector2 in corners:
		_min_pos.x = minf(_min_pos.x, corner.x)
		_min_pos.y = minf(_min_pos.y, corner.y)
		_max_pos.x = maxf(_max_pos.x, corner.x)
		_max_pos.y = maxf(_max_pos.y, corner.y)
	_tracking = true

func _process(_delta: float) -> void:
	if not _tracking or _player == null:
		return
	var span := _max_pos - _min_pos
	var t := Vector2(
		clampf((_player.global_position.x - _min_pos.x) / maxf(span.x, 1.0), 0.0, 1.0),
		clampf((_player.global_position.y - _min_pos.y) / maxf(span.y, 1.0), 0.0, 1.0)
	)
	_dot.position = t * _clip.size - _dot.size * 0.5
