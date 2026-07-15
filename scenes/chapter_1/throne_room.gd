extends Node2D

func _ready() -> void:
	var cam: Camera2D = $YSortRoot/Player/Camera2D
	cam.limit_right = 562
	cam.limit_bottom = 526
	# room is smaller than the 1.3x view, zoom in so the camera has room to move
	cam.zoom = Vector2(2.1, 2.1)
 
