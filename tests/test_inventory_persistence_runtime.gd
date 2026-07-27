extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inv := root.get_node_or_null("Inv")
	if inv == null:
		_fail("Inv autoload was not available")
		return

	inv.call("restore_items", {"potion": 2, "jatayu_feather": 3, "key": 1})
	var snapshot: Dictionary = inv.call("get_items_snapshot")
	snapshot["jatayu_feather"] = 99
	if int(inv.call("count", "jatayu_feather")) != 3:
		_fail("Inventory snapshot leaked a shared dictionary reference")
		return

	inv.call("reset_for_new_story")
	if int(inv.call("count", "potion")) != 3:
		_fail("Ending reset did not restore three healing potions")
		return
	if int(inv.call("count", "jatayu_feather")) != 0:
		_fail("Ending reset kept Jatayu feathers")
		return
	if int(inv.call("count", "key")) != 0:
		_fail("Ending reset kept another non-potion item")
		return

	print("Inventory persistence runtime passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
