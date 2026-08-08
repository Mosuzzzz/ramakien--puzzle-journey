extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const HANUMAN_SCENE := preload("res://scenes/player/hanuman_player.tscn")

const MAGIC_TRAIL_QUESTIONS := [
	{
		"question": "คำใดสะกดถูกต้อง",
		"choices": ["อนุญาติ", "อนุญาต", "อนุยาต"],
		"correct_index": 1,
	},
	{
		"question": "ข้อใดใช้ภาษาได้สุภาพที่สุด",
		"choices": ["เฮ้ย เอาของมาให้หน่อย", "ช่วยหยิบหนังสือให้ฉันหน่อยได้ไหม", "เอาหนังสือมาเดี๋ยวนี้"],
		"correct_index": 1,
	},
	{
		"question": "ข้อใดเป็นคำอุทาน",
		"choices": ["โอ๊ย! เจ็บจัง", "ฉันเดินไปโรงเรียน", "น้องอ่านหนังสือ"],
		"correct_index": 0,
	},
	{
		"question": "คำว่า “เขา” ในประโยค “เขากำลังเล่นฟุตบอล” เป็นคำชนิดใด",
		"choices": ["คำนาม", "คำสรรพนาม", "คำกริยา"],
		"correct_index": 1,
	},
]

# จุดทั้งหมดผ่านการตรวจพื้นที่ชนและเชื่อมถึงกันบนทางเดินจริง
# แต่ละกลุ่มอยู่ใกล้ประตู Chapter 5 มากกว่ากลุ่มก่อนหน้า
const MAGIC_TRAIL_POINT_POOLS := [
	[
		Vector2(624, 888),
		Vector2(732, 864),
		Vector2(264, 576),
	],
	[
		Vector2(708, 780),
		Vector2(852, 720),
		Vector2(636, 708),
		Vector2(744, 684),
		Vector2(468, 684),
		Vector2(936, 660),
		Vector2(1092, 636),
		Vector2(564, 636),
		Vector2(372, 624),
		Vector2(276, 576),
	],
	[
		Vector2(768, 624),
		Vector2(660, 624),
		Vector2(708, 528),
	],
	[
		Vector2(708, 504),
		Vector2(744, 408),
	],
	[
		Vector2(708, 348),
		Vector2(744, 252),
	],
]

var _hanuman_active := false
var _magic_trail_started := false
var _magic_trail_progress := 0
var _magic_trail_rng := RandomNumberGenerator.new()

@onready var _magic_trail: Area2D = $YSortRoot/MagicTrail
@onready var _magic_trail_quiz: CanvasLayer = $MagicTrailQuiz
@onready var _chapter_5_portal: Area2D = $YSortRoot/Chapter5Portal


func _ready() -> void:
	_magic_trail_rng.randomize()
	_chapter_5_portal.call("set_locked", true)
	_magic_trail.interaction_requested.connect(_on_magic_trail_interaction_requested)
	_magic_trail_quiz.answered.connect(_on_magic_trail_answered)
	Quest.clear()

	if GameState.chapter_4_intro_played:
		if not GameState.chapter_5_post_boss_played:
			_switch_to_hanuman_on_load()
		if GameState.chapter_4_magic_trail_completed:
			_chapter_5_portal.call("set_locked", false)
			_magic_trail.hide()
			_magic_trail.process_mode = PROCESS_MODE_DISABLED
			_start_follow_thosakan_quest()
		else:
			# The cutscene normally starts this quest after switching players.
			# Loading skips the cutscene, so restore the same gameplay state here.
			start_magic_trail_quest.call_deferred()


func switch_player_to_hanuman() -> void:
	if _hanuman_active:
		return
	_hanuman_active = true

	var old_player := get_node_or_null("YSortRoot/Player") as Node2D
	var player_position := Vector2(691, 863)
	var player_health := -1
	if old_player != null:
		player_position = old_player.position
		if "current_health" in old_player:
			player_health = old_player.current_health
		old_player.get_parent().remove_child(old_player)
		old_player.queue_free()

	var hanuman := HANUMAN_SCENE.instantiate() as Node2D
	hanuman.name = "Player"
	if player_health >= 0 and "current_health" in hanuman:
		hanuman.current_health = player_health
	$YSortRoot.add_child(hanuman)
	hanuman.position = player_position
	call_deferred("start_magic_trail_quest")


func _switch_to_hanuman_on_load() -> void:
	if _hanuman_active:
		return
	_hanuman_active = true

	var old_player := get_node_or_null("YSortRoot/Player") as Node2D
	var player_position := Vector2(691, 863)
	var player_health := -1
	if old_player != null:
		player_position = old_player.position
		if "current_health" in old_player:
			player_health = old_player.current_health
		old_player.get_parent().remove_child(old_player)
		old_player.queue_free()

	var hanuman := HANUMAN_SCENE.instantiate() as Node2D
	hanuman.name = "Player"
	if player_health >= 0 and "current_health" in hanuman:
		hanuman.current_health = player_health
	$YSortRoot.add_child(hanuman)
	hanuman.position = player_position



func start_magic_trail_quest() -> void:
	if _magic_trail_started:
		return
	_magic_trail_started = true
	_magic_trail_progress = 0
	_chapter_5_portal.call("set_locked", true)
	_magic_trail.call("activate_at", _pick_magic_trail_point(0))
	_update_magic_trail_quest()


func get_magic_trail_progress() -> int:
	return _magic_trail_progress


func set_magic_trail_random_seed(seed_value: int) -> void:
	_magic_trail_rng.seed = seed_value


func get_magic_trail_point_pools() -> Array:
	return MAGIC_TRAIL_POINT_POOLS.duplicate(true)


func _pick_magic_trail_point(pool_index: int) -> Vector2:
	var safe_index := clampi(pool_index, 0, MAGIC_TRAIL_POINT_POOLS.size() - 1)
	var pool: Array = MAGIC_TRAIL_POINT_POOLS[safe_index]
	var candidates := pool.duplicate()
	if candidates.size() > 1:
		candidates.erase(_magic_trail.global_position)
	return candidates[_magic_trail_rng.randi_range(0, candidates.size() - 1)]


func _on_magic_trail_interaction_requested(_trail: Area2D) -> void:
	if not _magic_trail_started or _magic_trail_progress >= MAGIC_TRAIL_QUESTIONS.size():
		return
	var data: Dictionary = MAGIC_TRAIL_QUESTIONS[_magic_trail_progress]
	_magic_trail_quiz.call(
		"ask",
		data["question"],
		data["choices"],
		data["correct_index"]
	)


func _on_magic_trail_answered(correct: bool) -> void:
	if correct:
		_magic_trail_progress += 1
		_update_magic_trail_quest()
		if _magic_trail_progress >= MAGIC_TRAIL_QUESTIONS.size():
			GameState.chapter_4_magic_trail_completed = true
			_chapter_5_portal.call("set_locked", false)
			await _magic_trail.call(
				"move_to",
				_pick_magic_trail_point(MAGIC_TRAIL_POINT_POOLS.size() - 1)
			)
			await _magic_trail.call("fade_out")
			_start_follow_thosakan_quest()
		else:
			await _magic_trail.call(
				"move_to",
				_pick_magic_trail_point(_magic_trail_progress)
			)
			Quest.set_targets([_magic_trail])
		return

	var farther_pool_index := maxi(_magic_trail_progress - 1, 0)
	await _magic_trail.call("move_to", _pick_magic_trail_point(farther_pool_index))
	Quest.set_targets([_magic_trail])


func _update_magic_trail_quest() -> void:
	var completed := _magic_trail_progress >= MAGIC_TRAIL_QUESTIONS.size()
	var quest_name := "ตามรอยมนตร์ %d/%d" % [
		_magic_trail_progress,
		MAGIC_TRAIL_QUESTIONS.size(),
	]
	var detail := "ติดตามร่องรอยเวทมนตร์ไปยังทางออกของด่าน"
	if completed:
		detail = "พบเส้นทางไปยังด่านถัดไปแล้ว"
	Quest.set_quest(quest_name, detail)
	Quest.set_completed(completed)
	if completed:
		Quest.set_targets([_chapter_5_portal])
	else:
		Quest.set_targets([_magic_trail])


func _start_follow_thosakan_quest() -> void:
	Quest.set_quest(
		"ตามรอยทศกัณฐ์",
		"เดินทางออกจากป่าเพื่อตามหานางสีดา"
	)
	Quest.set_targets([_chapter_5_portal])


func _exit_tree() -> void:
	if is_instance_valid(Quest):
		Quest.clear()
