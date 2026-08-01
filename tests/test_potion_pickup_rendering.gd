extends SceneTree

const POTION_PICKUP_PATH := "res://scenes/props/potion_pickup.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var pickup := (load(POTION_PICKUP_PATH) as PackedScene).instantiate()
	root.add_child(pickup)
	_expect(pickup.z_index > 0, "potion pickup renders above default-z foreground art")
	_expect(pickup.collision_layer == 0, "rendering fix does not turn the pickup into a blocking body")
	_expect(pickup.collision_mask == 2, "rendering fix preserves player detection")
	pickup.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: potion pickup rendering")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
