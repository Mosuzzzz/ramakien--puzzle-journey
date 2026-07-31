extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const FEATHER_TOTAL := 3
const FEATHER_QUEST_NAME := "ตามหาขนนกพญาชฎายุ"
const FEATHER_QUEST_DETAIL := "รวบรวมขนนกพญาชฎายุที่ตกหล่นให้ครบ %d/3"
const EXIT_QUEST_NAME := "ตามรอยทศกัณฐ์"
const EXIT_QUEST_DETAIL := "เดินทางออกจากป่าเพื่อตามหานางสีดา"
const REST_QUEST_NAME := "พักผ่อนใต้ต้นไม้ใหญ่"
const REST_QUEST_DETAIL := "เก็บขนนกครบแล้ว เดินทางไปยังต้นไม้ใหญ่กลางป่าเพื่อพักผ่อน"
const REST_ARRIVAL_DISTANCE := 60.0
const FEATHER_QUESTIONS: Array[Array] = [
	[
		"คำใดอยู่ในมาตราตัวสะกดแม่กง",
		["ลิง", "ดาว", "เมฆ"],
		0,
	],
	[
		"คำว่า “วิ่ง” เป็นคำชนิดใด",
		["คำนาม", "คำกริยา", "คำวิเศษณ์"],
		1,
	],
	[
		"คำว่า “สามัคคี” หมายถึงข้อใด",
		["การแข่งขันกัน", "การร่วมมือและพร้อมใจกัน", "การอยู่ตามลำพัง"],
		1,
	],
]

var _post_battle_cutscene_started := false
var _feather_quest_started := false
var _resting_quest_active := false
var _quiz_open := false
var _pending_feather: Area2D = null
var _rng := RandomNumberGenerator.new()

@onready var _post_battle_cutscene: Control = $Chapter3CutsceneLayer/PostBattleCutscene
@onready var _player: CharacterBody2D = $YSortRoot/Player
@onready var _hanuman: CharacterBody2D = $YSortRoot/Hanuman
@onready var _chapter4_portal: Area2D = $YSortRoot/Chapter4Portal
@onready var _story_end_spawn: Marker2D = $StoryEndSpawn
@onready var _quiz: CanvasLayer = $QuestionQuiz
@onready var _feathers: Array[Area2D] = [
	$YSortRoot/Feather1,
	$YSortRoot/Feather2,
	$YSortRoot/Feather3,
]
@onready var _spawn_points: Array[Node2D] = [
	$FeatherSpawns/Spawn1,
	$FeatherSpawns/Spawn2,
	$FeatherSpawns/Spawn3,
	$FeatherSpawns/Spawn4,
	$FeatherSpawns/Spawn5,
	$FeatherSpawns/Spawn6,
]


func _ready() -> void:
	Quest.clear()
	if GameState.chapter_3_post_battle_played:
		_hanuman.show()
		_chapter4_portal.set_locked(false)
	else:
		_hide_hanuman_until_all_cutscenes_finish()
	_quiz.answered.connect(_on_quiz_answered)
	_rng.randomize()
	for feather: Area2D in _feathers:
		feather.call("mark_collected")
		feather.collection_requested.connect(_on_feather_collection_requested)


func _physics_process(_delta: float) -> void:
	if not _resting_quest_active:
		return
	if _player.global_position.distance_to(_story_end_spawn.global_position) <= REST_ARRIVAL_DISTANCE:
		_resting_quest_active = false
		_start_post_battle_cutscene()


func start_feather_quest() -> void:
	if _feather_quest_started:
		return
	_feather_quest_started = true
	_spawn_remaining_feathers()
	_update_feather_quest()
	if Inv.count("jatayu_feather") >= FEATHER_TOTAL:
		call_deferred("_start_resting_quest")


func _spawn_remaining_feathers() -> void:
	var shuffled_spawns := _spawn_points.duplicate()
	shuffled_spawns.shuffle()
	var already_collected := clampi(Inv.count("jatayu_feather"), 0, FEATHER_TOTAL)
	for index: int in _feathers.size():
		var feather := _feathers[index]
		if index < already_collected:
			feather.call("mark_collected")
			continue
		var spawn := shuffled_spawns[index - already_collected] as Node2D
		var spawn_index := _spawn_points.find(spawn)
		feather.set_meta("spawn_index", spawn_index)
		feather.call("activate_at", spawn.global_position)


func _on_feather_collection_requested(feather: Area2D) -> void:
	if not _feather_quest_started or _quiz_open or not is_instance_valid(feather):
		if is_instance_valid(feather):
			feather.call("set_interaction_enabled", true)
		return
	_quiz_open = true
	_pending_feather = feather
	var feather_index := _feathers.find(feather)
	if feather_index < 0:
		_quiz_open = false
		_pending_feather = null
		feather.call("set_interaction_enabled", true)
		return
	var question: Array = FEATHER_QUESTIONS[feather_index]
	_quiz.call("ask", question[0], question[1], question[2])


func _on_quiz_answered(correct: bool) -> void:
	_quiz_open = false
	var feather := _pending_feather
	_pending_feather = null
	if not is_instance_valid(feather):
		return
	if correct:
		feather.call("mark_collected")
		Inv.add_item("jatayu_feather")
		_update_feather_quest()
		if Inv.count("jatayu_feather") >= FEATHER_TOTAL:
			call_deferred("_start_resting_quest")
		return
	var relocation := _choose_relocation(feather)
	await feather.call("fade_and_relocate", relocation)
	_update_feather_quest()


func _choose_relocation(feather: Area2D) -> Vector2:
	var occupied: Array[int] = []
	for other: Area2D in _feathers:
		if other == feather or not other.visible or not other.monitoring:
			continue
		occupied.append(int(other.get_meta("spawn_index", -1)))
	var current_index := int(feather.get_meta("spawn_index", -1))
	var available: Array[int] = []
	for index: int in _spawn_points.size():
		if index != current_index and not occupied.has(index):
			available.append(index)
	if available.is_empty():
		available.append(current_index)
	var next_index := available[_rng.randi_range(0, available.size() - 1)]
	feather.set_meta("spawn_index", next_index)
	return _spawn_points[next_index].global_position


func _active_feathers() -> Array[Node2D]:
	var active: Array[Node2D] = []
	for feather: Area2D in _feathers:
		if feather.visible and feather.monitoring:
			active.append(feather)
	return active


func _update_feather_quest() -> void:
	if not _feather_quest_started:
		return
	var collected_count := clampi(Inv.count("jatayu_feather"), 0, FEATHER_TOTAL)
	Quest.set_quest(
		FEATHER_QUEST_NAME,
		FEATHER_QUEST_DETAIL % collected_count
	)
	Quest.set_targets(_active_feathers())
	Quest.set_completed(collected_count == FEATHER_TOTAL)


func _start_resting_quest() -> void:
	if _post_battle_cutscene_started or GameState.chapter_3_post_battle_played:
		return
	_resting_quest_active = true
	Quest.set_quest(REST_QUEST_NAME, REST_QUEST_DETAIL, _story_end_spawn.global_position)


func _start_post_battle_cutscene() -> void:
	if (
		not _feather_quest_started
		or _post_battle_cutscene_started
		or GameState.chapter_3_post_battle_played
		or Inv.count("jatayu_feather") < FEATHER_TOTAL
		or not is_inside_tree()
	):
		return
	await get_tree().create_timer(0.35).timeout
	if _post_battle_cutscene_started or GameState.chapter_3_post_battle_played or not is_inside_tree():
		return
	_post_battle_cutscene_started = true
	GameState.chapter_3_post_battle_played = true
	_post_battle_cutscene.call("show_cutscene")


func _hide_hanuman_until_all_cutscenes_finish() -> void:
	_hanuman.hide()
	_hanuman.process_mode = Node.PROCESS_MODE_DISABLED


func reveal_hanuman_after_all_cutscenes() -> void:
	# stays visible but doesn't patrol in chapter 3 — he only starts moving
	# with the party once chapter 4 begins
	_hanuman.show()


func finish_chapter_3_story() -> void:
	_player.velocity = Vector2.ZERO
	_player.global_position = _story_end_spawn.global_position
	reveal_hanuman_after_all_cutscenes()
	_chapter4_portal.set_locked(false)
	Quest.set_quest(EXIT_QUEST_NAME, EXIT_QUEST_DETAIL, _chapter4_portal.global_position)


func _exit_tree() -> void:
	if is_instance_valid(Quest):
		Quest.clear()
