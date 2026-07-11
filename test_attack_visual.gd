extends Node

func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().current_scene
	var player := root.get_node("YSortRoot/Player") as Node2D
	var mob := root.get_node("YSortRoot/Mob3") as Node2D
	player.global_position = mob.global_position + Vector2(-30, 0)
