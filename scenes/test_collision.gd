extends Node
func _ready():
	var player = get_parent().get_node("YSortRoot/Player")
	player.position = Vector2(700, 560)  # just above/near tree_green1_0 at (700,500)
	await get_tree().process_frame
	Input.action_press("ui_up")
