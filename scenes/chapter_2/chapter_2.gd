extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")

const SUPPLY_PAIRS := [
	["ฟืน", "สำหรับก่อไฟหุงหาอาหาร"],
	["น้ำจากลำธาร", "สำหรับดื่มและประกอบอาหาร"],
	["สมุนไพร", "สำหรับรักษาบาดแผล"],
	["ใบไม้แห้ง", "สำหรับปูที่นอน"],
]

const HOME_RADIUS := 90.0

var _abduction_started := false
var _waiting_for_home := false

@onready var _chapter3_portal: Area2D = $YSortRoot/Chapter3Portal
@onready var _forest_gate: Area2D = $YSortRoot/ForestGate
@onready var _golden_deer: CharacterBody2D = $YSortRoot/GoldenDeer
@onready var _sida: Node2D = $YSortRoot/Sida
@onready var _player: Node2D = $YSortRoot/Player
@onready var _puzzle_trigger: Area2D = $YSortRoot/PuzzleTrigger
@onready var _ashram_home: Marker2D = $YSortRoot/AshramHome
@onready var _matching_puzzle: CanvasLayer = $MatchingPuzzle
@onready var _intro_cutscene: Control = $Chapter2IntroCutsceneLayer/Chapter2Cutscene
@onready var _deer_cutscene: Control = $Chapter2DeerCutsceneLayer/Chapter2DeerCutscene
@onready var _abduction_cutscene: Control = $Chapter2AbductionCutsceneLayer/AbductionCutscene


func _ready() -> void:
	# only ever play the intro cutscene once; on any revisit it's removed
	# no matter which phase we resume into
	if GameState.chapter_2_intro_played:
		_intro_cutscene.get_parent().queue_free()

	if GameState.chapter_2_deer_defeated:
		_golden_deer.queue_free()
		_sida.queue_free()
		_puzzle_trigger.queue_free()
		_chapter3_portal.set_locked(false)
		if not GameState.chapter_2_aftermath_played:
			GameState.chapter_2_aftermath_played = true
			Quest.set_quest(
				"ตามรอยทศกัณฐ์", "เดินทางออกจากป่าเพื่อตามหานางสีดา", _chapter3_portal.global_position
			)
		return

	_golden_deer.defeated.connect(_on_deer_defeated)
	_golden_deer.escaped.connect(_on_deer_escaped)

	if GameState.chapter_2_deer_intro_played:
		_puzzle_trigger.queue_free()
		_forest_gate.set_locked(false)
		Quest.set_quest(
			"ไล่ตามกวางทอง", "เข้าไปใกล้ ๆ กวางทอง แล้วยิงธนูใส่มัน (กด Space)", _golden_deer.global_position
		)
		return

	# the deer doesn't exist in the story yet — keep it hidden and inert
	_golden_deer.hide()
	_golden_deer.process_mode = Node.PROCESS_MODE_DISABLED

	if GameState.chapter_2_ashram_puzzle_solved:
		_puzzle_trigger.queue_free()
		_start_waiting_for_home()
		return

	_puzzle_trigger.activated.connect(_on_puzzle_trigger_activated)

	if GameState.chapter_2_intro_played:
		_start_ashram_quest()
		return

	GameState.chapter_2_intro_played = true
	_intro_cutscene.finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
	_intro_cutscene.call("show_cutscene")


func _process(_delta: float) -> void:
	if _waiting_for_home:
		if _player.global_position.distance_to(_ashram_home.global_position) < HOME_RADIUS:
			_waiting_for_home = false
			_on_reached_home()
		return
	# ponytail: re-poke the quest marker each frame while chasing the deer so
	# it tracks the deer's live position instead of where it was when the
	# quest text was first set
	if GameState.chapter_2_deer_intro_played and not _abduction_started and is_instance_valid(_golden_deer) and _golden_deer.visible:
		Quest.target_position = _golden_deer.global_position


func _on_intro_finished() -> void:
	_start_ashram_quest()


func _start_ashram_quest() -> void:
	Quest.set_quest(
		"สำรวจรอบอาศรม", "หาของใช้ที่จำเป็นรอบอาศรม แล้วจับคู่ให้ถูกต้อง", _puzzle_trigger.global_position
	)


func _on_puzzle_trigger_activated() -> void:
	_matching_puzzle.solved.connect(_on_puzzle_solved, CONNECT_ONE_SHOT)
	_matching_puzzle.call("open", "จัดเตรียมของใช้ในอาศรม", SUPPLY_PAIRS)


func _on_puzzle_solved() -> void:
	GameState.chapter_2_ashram_puzzle_solved = true
	_puzzle_trigger.queue_free()
	_start_waiting_for_home()


func _start_waiting_for_home() -> void:
	_waiting_for_home = true
	Quest.set_quest("กลับไปที่อาศรม", "เดินกลับไปยังอาศรมเพื่อพักผ่อน", _ashram_home.global_position)


func _on_reached_home() -> void:
	GameState.chapter_2_deer_intro_played = true
	_golden_deer.process_mode = Node.PROCESS_MODE_INHERIT
	_golden_deer.show()
	_deer_cutscene.finished.connect(_on_deer_cutscene_finished, CONNECT_ONE_SHOT)
	_deer_cutscene.call("show_cutscene")


func _on_deer_cutscene_finished() -> void:
	_forest_gate.set_locked(false)
	Quest.set_quest(
		"ไล่ตามกวางทอง", "เข้าไปใกล้ ๆ กวางทอง แล้วยิงธนูใส่มัน (กด Space)", _golden_deer.global_position
	)


func _on_deer_escaped() -> void:
	Quest.set_quest(
		"ตามกวางทองเข้าป่าลึก", "กวางทองหนีออกไปทางประตูป่าด้านตะวันออก ตามมันไป!", _forest_gate.global_position
	)


func _on_deer_defeated() -> void:
	if _abduction_started:
		return
	_abduction_started = true
	GameState.chapter_2_deer_defeated = true
	_abduction_cutscene.finished.connect(_on_abduction_finished, CONNECT_ONE_SHOT)
	_abduction_cutscene.call("show_cutscene")


func _on_abduction_finished() -> void:
	GameState.chapter_2_aftermath_played = true
	_sida.queue_free()
	_chapter3_portal.set_locked(false)
	Quest.set_quest(
		"ตามรอยทศกัณฐ์", "เดินทางออกจากป่าเพื่อตามหานางสีดา", _chapter3_portal.global_position
	)
