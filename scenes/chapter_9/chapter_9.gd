extends Node2D

const CameraFraming := preload("res://scenes/core/camera_framing.gd")
const GameState := preload("res://scenes/core/game_state.gd")
const CAMERA_BASE_ZOOM := 1.3
const CAMERA_COVER_MARGIN := 1.01
const QUEST_BOSS_NAME := "ปราบทศกัณฐ์"
const QUEST_BOSS_DETAIL := "เอาชนะทศกัณฐ์เพื่อปลดล็อกห้องที่คุมขังนางสีดา"
const QUEST_RESCUE_NAME := "กลับไปช่วยนางสีดา"
const QUEST_RESCUE_DETAIL := "กลับไปยังพระราชวังและช่วยนางสีดาจากห้องที่ถูกล็อก"

@onready var _thotsakan: CharacterBody2D = $YSortRoot/Thotsakan
@onready var _sida: CharacterBody2D = $YSortRoot/Sida
@onready var _ending_cutscene: Control = $Chapter9EndingCutsceneLayer/Chapter9EndingCutscene
@onready var _background: Sprite2D = $Background
@onready var _player: CharacterBody2D = $YSortRoot/Player
@onready var _chapter_9_props: Node2D = $Chapter9Props
@onready var _y_sort_root: Node2D = $YSortRoot


func _ready() -> void:
	configure_props_above_characters(_chapter_9_props, _y_sort_root)

	if GameState.chapter_9_thotsakan_defeated:
		_show_rescue_quest()
		if GameState.chapter_9_sida_rescued:
			Quest.set_completed(true)
		AudioManager.restore_background_music(0.0)
		_thotsakan.queue_free()
	elif not _thotsakan.defeated.is_connected(_on_thotsakan_defeated):
		Quest.set_quest(QUEST_BOSS_NAME, QUEST_BOSS_DETAIL)
		AudioManager.play_boss_music()
		_thotsakan.defeated.connect(_on_thotsakan_defeated)

	if GameState.chapter_9_sida_rescued:
		_sida.start_following()
	else:
		_sida.queue_free()

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_configure_chapter_9_camera")


static func configure_props_above_characters(props: CanvasItem, actors: CanvasItem) -> void:
	if props == null or actors == null:
		return
	props.z_as_relative = false
	props.z_index = actors.z_index + 1


func _on_viewport_size_changed() -> void:
	call_deferred("_configure_chapter_9_camera")


func _configure_chapter_9_camera() -> void:
	if not is_instance_valid(_background) or _background.texture == null:
		return
	if not is_instance_valid(_player):
		return
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var map_rect := _background_global_rect(_background)
	if map_rect.size.x <= 0.0 or map_rect.size.y <= 0.0:
		return

	camera.limit_left = floori(map_rect.position.x)
	camera.limit_top = floori(map_rect.position.y)
	camera.limit_right = ceili(map_rect.end.x)
	camera.limit_bottom = ceili(map_rect.end.y)
	var zoom_value := CameraFraming.cover_zoom(
		get_viewport_rect().size,
		map_rect.size,
		CAMERA_BASE_ZOOM,
		CAMERA_COVER_MARGIN
	)
	camera.zoom = Vector2(zoom_value, zoom_value)
	camera.reset_smoothing()


func _background_global_rect(background: Sprite2D) -> Rect2:
	var rect := background.get_rect()
	var corners: Array[Vector2] = [
		background.to_global(rect.position),
		background.to_global(rect.position + Vector2(rect.size.x, 0.0)),
		background.to_global(rect.position + Vector2(0.0, rect.size.y)),
		background.to_global(rect.end),
	]
	var min_pos := corners[0]
	var max_pos := corners[0]
	for corner in corners:
		min_pos.x = minf(min_pos.x, corner.x)
		min_pos.y = minf(min_pos.y, corner.y)
		max_pos.x = maxf(max_pos.x, corner.x)
		max_pos.y = maxf(max_pos.y, corner.y)
	return Rect2(min_pos, max_pos - min_pos)


func _on_thotsakan_defeated(_defeated_thotsakan: CharacterBody2D) -> void:
	GameState.chapter_9_thotsakan_defeated = true
	AudioManager.restore_background_music()
	_show_rescue_quest()


func _show_rescue_quest() -> void:
	Quest.set_quest(QUEST_RESCUE_NAME, QUEST_RESCUE_DETAIL)


func show_ending_cutscene() -> void:
	_ending_cutscene.show_cutscene()
