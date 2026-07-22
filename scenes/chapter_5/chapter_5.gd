extends Node2D

const PHRA_RAM_SCENE := preload("res://scenes/player/player.tscn")

var _post_boss_cutscene_started := false
var _phra_ram_restored := false

@onready var _post_boss_cutscene: Control = $Chapter5CutsceneLayer/Chapter5PostBossCutscene


func _ready() -> void:
	var boss := get_node_or_null("YSortRoot/Miyarap")
	if boss != null:
		boss.tree_exited.connect(_on_miyarap_removed)


func _on_miyarap_removed() -> void:
	call_deferred("_show_post_boss_cutscene")


func _show_post_boss_cutscene() -> void:
	if _post_boss_cutscene_started or not is_inside_tree():
		return
	if get_node_or_null("YSortRoot/Miyarap") != null:
		return
	_post_boss_cutscene_started = true
	_post_boss_cutscene.call("show_cutscene")


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
