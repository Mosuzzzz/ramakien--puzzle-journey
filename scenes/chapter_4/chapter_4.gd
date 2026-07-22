extends Node2D

const HANUMAN_SCENE := preload("res://scenes/player/hanuman_player.tscn")

var _hanuman_active := false


func switch_player_to_hanuman() -> void:
	if _hanuman_active:
		return
	_hanuman_active = true

	var old_player := get_node_or_null("YSortRoot/Player") as Node2D
	var player_position := Vector2(691, 863)
	if old_player != null:
		player_position = old_player.position
		old_player.get_parent().remove_child(old_player)
		old_player.queue_free()

	var hanuman := HANUMAN_SCENE.instantiate() as Node2D
	hanuman.name = "Player"
	$YSortRoot.add_child(hanuman)
	hanuman.position = player_position
