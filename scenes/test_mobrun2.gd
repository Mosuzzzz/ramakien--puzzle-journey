extends Node
func _ready():
	var player = get_parent().get_node("YSortRoot/Player")
	player.position = Vector2(1030, 700)
