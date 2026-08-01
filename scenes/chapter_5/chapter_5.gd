extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const PHRA_RAM_SCENE := preload("res://scenes/player/player.tscn")

var _post_boss_cutscene_started := false
var _phra_ram_restored := false

@onready var _post_boss_cutscene: Control = $Chapter5CutsceneLayer/Chapter5PostBossCutscene
@onready var _chapter6_portal: Area2D = $YSortRoot/Chapter6Portal


func _ready() -> void:
	if not _post_boss_cutscene.finished.is_connected(_on_post_boss_cutscene_finished):
		_post_boss_cutscene.finished.connect(_on_post_boss_cutscene_finished)
	var boss := get_node_or_null("YSortRoot/Miyarap")
	if GameState.chapter_5_post_boss_played:
		AudioManager.restore_background_music(0.0)
		if boss != null:
			boss.queue_free()
		_chapter6_portal.set_locked(false)
	elif boss != null:
		AudioManager.play_boss_music()
		boss.tree_exited.connect(_on_miyarap_removed)
	else:
		AudioManager.restore_background_music(0.0)
		_chapter6_portal.set_locked(false)


func _on_miyarap_removed() -> void:
	_chapter6_portal.set_locked(false)
	call_deferred("_show_post_boss_cutscene")


func _show_post_boss_cutscene() -> void:
	if _post_boss_cutscene_started or GameState.chapter_5_post_boss_played or not is_inside_tree():
		return
	if get_node_or_null("YSortRoot/Miyarap") != null:
		return
	_post_boss_cutscene_started = true
	GameState.chapter_5_post_boss_played = true
	_post_boss_cutscene.call("show_cutscene")


func _on_post_boss_cutscene_finished() -> void:
	AudioManager.restore_background_music()


func restore_phra_ram_after_cutscene() -> void:
	if _phra_ram_restored:
		return
	_phra_ram_restored = true

	var old_player := get_node_or_null("YSortRoot/Player") as Node2D
	var player_position := Vector2(65, 574)
	if old_player != null:
		player_position = old_player.position
		old_player.get_parent().remove_child(old_player)
		old_player.queue_free()

	var phra_ram := PHRA_RAM_SCENE.instantiate() as Node2D
	phra_ram.name = "Player"
	$YSortRoot.add_child(phra_ram)
	phra_ram.position = player_position
