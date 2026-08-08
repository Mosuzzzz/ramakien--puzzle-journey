extends RefCounted

const GameState := preload("res://scenes/core/game_state.gd")

const SLOT_COUNT := 3
const AUTOSAVE_PATH := "user://autosave.json"

const CHAPTER_NAMES := {
	"res://scenes/prologue/prologue.tscn": "อารัมภบท",
	"res://scenes/chapter_1/chapter_1.tscn": "บทที่ 1",
	"res://scenes/chapter_2/chapter_2.tscn": "บทที่ 2",
	"res://scenes/chapter_2/chapter_2_second.tscn": "บทที่ 2",
	"res://scenes/chapter_3/chapter_3.tscn": "บทที่ 3",
	"res://scenes/chapter_4/chapter_4.tscn": "บทที่ 4",
	"res://scenes/chapter_5/chapter_5.tscn": "บทที่ 5",
	"res://scenes/chapter_6/chapter_6.tscn": "บทที่ 6",
	"res://scenes/chapter_7/chapter_7.tscn": "บทที่ 7",
	"res://scenes/chapter_8/chapter_8.tscn": "บทที่ 8",
	"res://scenes/chapter_8/chapter_8_room.tscn": "บทที่ 8",
	"res://scenes/chapter_8/chapter_8_room_2.tscn": "บทที่ 8",
	"res://scenes/chapter_8/chapter_8_room_3.tscn": "บทที่ 8",
	"res://scenes/chapter_8/chapter_8_room_4.tscn": "บทที่ 8",
	"res://scenes/chapter_9/chapter_9.tscn": "บทที่ 9",
}

# every GameState progress flag that should persist across a save/load
const STATE_KEYS := [
	"chapter_1_intro_played",
	"chapter_1_audience_done",
	"tutorial_shown",
	"chapter_2_intro_played",
	"chapter_2_deer_defeated",
	"chapter_2_ashram_puzzle_solved",
	"chapter_2_deer_intro_played",
	"chapter_2_aftermath_played",
	"chapter_6_intro_played",
	"chapter_6_yak_defeated",
	"chapter_6_left_chest_unlocked",
	"chapter_6_right_jars_mask",
	"chapter_6_right_pedestal_solved",
	"chapter_6_gate_unlocked",
	"chapter_7_defenders_cleared",
	"chapter_8_sida_room_discovered",
	"chapter_8_intro_played",
	"chapter_9_thotsakan_defeated",
	"chapter_9_sida_rescued",
	"chapter_3_intro_played",
	"chapter_3_post_battle_played",
	"chapter_4_intro_played",
	"chapter_4_magic_trail_completed",
	"chapter_5_post_boss_played",
]


static func _slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


## returns {"exists": false} for an empty slot, otherwise the saved data
## plus "exists": true and a human-readable "chapter_name"
static func slot_info(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {"exists": false}
	data["exists"] = true
	data["chapter_name"] = CHAPTER_NAMES.get(data.get("scene_path", ""), "ไม่ทราบบท")
	return data


static func has_any_save() -> bool:
	for slot in range(SLOT_COUNT):
		if slot_info(slot).exists:
			return true
	return false


static func save_to_slot(slot: int) -> void:
	_save_to_path(_slot_path(slot))


## restores GameState flags and changes to the saved scene/position
static func load_slot(slot: int) -> void:
	_load_from_path(_slot_path(slot))


static func delete_slot(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## a single reserved slot the game writes to automatically (Settings.auto_save_enabled),
## separate from the 3 player-chosen save slots so it never overwrites one
static func save_autosave() -> void:
	_save_to_path(AUTOSAVE_PATH)


static func has_autosave() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)


static func load_autosave() -> void:
	_load_from_path(AUTOSAVE_PATH)


static func _save_to_path(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_warning("SaveGame: cannot save without an active SceneTree")
		return
	var scene := tree.current_scene
	if scene == null:
		push_warning("SaveGame: cannot save without an active scene")
		return
	var player := scene.get_node_or_null("YSortRoot/Player") as Node2D
	var inventory = tree.root.get_node_or_null("Inv")
	var data := {
		"scene_path": scene.scene_file_path,
		"player_position": [player.global_position.x, player.global_position.y] if player else null,
		"player_health": player.current_health if player else null,
		"timestamp": Time.get_datetime_string_from_system(),
		"inventory": inventory.get_items_snapshot() if inventory != null else {},
	}
	# GameState is preloaded with a strict static type, which the compiler
	# refuses for dynamic get()/set() by key — load() again here as a loose
	# Variant handle to the same script class just for that
	var state_dyn = load("res://scenes/core/game_state.gd")
	for key in STATE_KEYS:
		data[key] = state_dyn.get(key)
	# capture the active quest so it survives a load (chapter _ready() logic
	# often skips re-setting it once its one-time flag is already true)
	var quest := tree.root.get_node_or_null("Quest")
	if quest != null:
		data["quest"] = quest.snapshot()
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))


static func _load_from_path(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_warning("SaveGame: cannot load without an active SceneTree")
		return
	var state_dyn = load("res://scenes/core/game_state.gd")
	for key in STATE_KEYS:
		if data.has(key):
			state_dyn.set(key, data[key])
	var inventory = tree.root.get_node_or_null("Inv")
	if data.has("inventory"):
		inventory.restore_items(data["inventory"])
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	var pos = data.get("player_position")
	GameState.next_spawn = Vector2(pos[0], pos[1]) if pos else Vector2.INF
	var saved_health = data.get("player_health")
	GameState.next_health = saved_health if saved_health != null else -1
	# hand the saved quest to the next gameplay scene to re-apply on _ready
	GameState.next_quest = data.get("quest", {})
	tree.change_scene_to_file.call_deferred(data["scene_path"])
