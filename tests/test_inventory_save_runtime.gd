extends SceneTree

const SaveGame := preload("res://scenes/core/save_game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inv := root.get_node_or_null("Inv")
	if inv == null:
		_fail("Inv autoload was not available")
		return

	var test_scene: Node = load("res://scenes/ending/ending.tscn").instantiate()
	root.add_child(test_scene)
	current_scene = test_scene

	inv.call("restore_items", {"potion": 1, "jatayu_feather": 2})
	SaveGame.save_to_slot(2)
	var saved := SaveGame.slot_info(2)
	if not saved.has("inventory"):
		_cleanup_and_fail("Save data did not contain inventory")
		return
	var saved_inventory: Dictionary = saved["inventory"]
	if int(saved_inventory.get("jatayu_feather", 0)) != 2:
		_cleanup_and_fail("Save data contained the wrong feather count")
		return

	inv.call("restore_items", {"potion": 3})
	SaveGame.load_slot(2)
	if int(inv.call("count", "jatayu_feather")) != 2:
		_cleanup_and_fail("Loading did not restore the saved feather count")
		return
	if int(inv.call("count", "potion")) != 1:
		_cleanup_and_fail("Loading did not restore the saved potion count")
		return

	SaveGame.delete_slot(2)
	print("Inventory save runtime passed")
	quit(0)


func _cleanup_and_fail(message: String) -> void:
	SaveGame.delete_slot(2)
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
