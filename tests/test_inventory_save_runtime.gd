extends SceneTree

const SaveGame := preload("res://scenes/core/save_game.gd")
const GameState := preload("res://scenes/core/game_state.gd")


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
	GameState.chapter_6_intro_played = true
	GameState.chapter_6_yak_defeated = true
	GameState.chapter_6_left_chest_unlocked = true
	GameState.chapter_6_yak_fragment_position = Vector2(500, 500)
	SaveGame.save_to_slot(2)
	var saved := SaveGame.slot_info(2)
	if not saved.has("inventory"):
		_cleanup_and_fail("Save data did not contain inventory")
		return
	var saved_inventory: Dictionary = saved["inventory"]
	if int(saved_inventory.get("jatayu_feather", 0)) != 2:
		_cleanup_and_fail("Save data contained the wrong feather count")
		return
	if not bool(saved.get("chapter_6_intro_played", false)):
		_cleanup_and_fail("Save data omitted Chapter 6 intro state")
		return
	if not bool(saved.get("chapter_6_yak_defeated", false)):
		_cleanup_and_fail("Save data omitted Chapter 6 Yak state")
		return
	if not bool(saved.get("chapter_6_left_chest_unlocked", false)):
		_cleanup_and_fail("Save data omitted Chapter 6 left chest state")
		return

	inv.call("restore_items", {"potion": 3})
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_left_chest_unlocked = false
	SaveGame.load_slot(2)
	if int(inv.call("count", "jatayu_feather")) != 2:
		_cleanup_and_fail("Loading did not restore the saved feather count")
		return
	if int(inv.call("count", "potion")) != 1:
		_cleanup_and_fail("Loading did not restore the saved potion count")
		return
	if not GameState.chapter_6_intro_played or not GameState.chapter_6_yak_defeated:
		_cleanup_and_fail("Loading did not restore Chapter 6 quest state")
		return
	if not GameState.chapter_6_left_chest_unlocked:
		_cleanup_and_fail("Loading did not restore Chapter 6 left chest state")
		return
	if GameState.chapter_6_yak_fragment_position != Vector2.INF:
		_cleanup_and_fail("Loading kept a stale Yak fragment position")
		return

	SaveGame.delete_slot(2)
	GameState.chapter_6_intro_played = false
	GameState.chapter_6_yak_defeated = false
	GameState.chapter_6_left_chest_unlocked = false
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	print("Inventory save runtime passed")
	quit(0)


func _cleanup_and_fail(message: String) -> void:
	SaveGame.delete_slot(2)
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
