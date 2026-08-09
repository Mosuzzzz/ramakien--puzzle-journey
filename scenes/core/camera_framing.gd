class_name CameraFraming
extends RefCounted


static func cover_zoom(
	viewport_size: Vector2,
	map_size: Vector2,
	base_zoom: float = 1.0,
	margin: float = 1.01
) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return base_zoom
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return base_zoom
	var required_zoom := maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y)
	return maxf(base_zoom, required_zoom * maxf(margin, 1.0))
