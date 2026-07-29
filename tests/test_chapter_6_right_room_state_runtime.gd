extends SceneTree

const SaveGame := preload("res://scenes/core/save_game.gd")
const GameState := preload("res://scenes/core/game_state.gd")
const TEST_SLOT := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_scene: Node = load("res://scenes/ending/ending.tscn").instantiate()
	root.add_child(test_scene)
	current_scene = test_scene

	GameState.chapter_6_right_jars_mask = 0b0101
	GameState.chapter_6_right_pedestal_solved = true
	GameState.chapter_6_gate_unlocked = true
	SaveGame.save_to_slot(TEST_SLOT)

	var saved := SaveGame.slot_info(TEST_SLOT)
	if int(saved.get("chapter_6_right_jars_mask", -1)) != 0b0101:
		_cleanup_and_fail("Save data omitted the right-room jar mask")
		return
	if not bool(saved.get("chapter_6_right_pedestal_solved", false)):
		_cleanup_and_fail("Save data omitted the right-room pedestal state")
		return
	if not bool(saved.get("chapter_6_gate_unlocked", false)):
		_cleanup_and_fail("Save data omitted the Chapter 6 gate state")
		return

	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false
	SaveGame.load_slot(TEST_SLOT)
	if GameState.chapter_6_right_jars_mask != 0b0101:
		_cleanup_and_fail("Loading did not restore the right-room jar mask")
		return
	if not GameState.chapter_6_right_pedestal_solved:
		_cleanup_and_fail("Loading did not restore the right-room pedestal state")
		return
	if not GameState.chapter_6_gate_unlocked:
		_cleanup_and_fail("Loading did not restore the Chapter 6 gate state")
		return

	var home: Control = load("res://scenes/homepage/home_page.tscn").instantiate()
	root.add_child(home)
	home.call("_on_start_pressed")
	if GameState.chapter_6_right_jars_mask != 0:
		_cleanup_and_fail("Starting a new story did not clear the jar mask")
		return
	if GameState.chapter_6_right_pedestal_solved:
		_cleanup_and_fail("Starting a new story kept the pedestal solved")
		return
	if GameState.chapter_6_gate_unlocked:
		_cleanup_and_fail("Starting a new story kept the city gate unlocked")
		return

	SaveGame.delete_slot(TEST_SLOT)
	GameState.chapter_6_right_jars_mask = 0
	GameState.chapter_6_right_pedestal_solved = false
	GameState.chapter_6_gate_unlocked = false
	print("Chapter 6 right-room state runtime passed")
	quit(0)


func _cleanup_and_fail(message: String) -> void:
	SaveGame.delete_slot(TEST_SLOT)
	push_error(message)
	quit(1)
