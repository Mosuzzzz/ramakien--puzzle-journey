extends Node2D

const GameState := preload("res://scenes/game_state.gd")

var _abduction_started := false

@onready var _chapter3_portal: Area2D = $YSortRoot/Chapter3Portal
@onready var _golden_deer: CharacterBody2D = $YSortRoot/GoldenDeer
@onready var _sida: Node2D = $YSortRoot/Sida
@onready var _intro_cutscene: Control = $Chapter2IntroCutsceneLayer/Chapter2Cutscene
@onready var _abduction_cutscene: Control = $Chapter2AbductionCutsceneLayer/AbductionCutscene


func _ready() -> void:
	if GameState.chapter_2_deer_defeated:
		_golden_deer.queue_free()
		_sida.queue_free()
		_chapter3_portal.set_locked(false)
	else:
		_golden_deer.defeated.connect(_on_deer_defeated)

	if GameState.chapter_2_intro_played:
		_intro_cutscene.get_parent().queue_free()
		return
	GameState.chapter_2_intro_played = true
	_intro_cutscene.finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)


func _on_intro_finished() -> void:
	Quest.set_quest(
		"ไล่ตามกวางทอง", "เข้าไปใกล้ ๆ กวางทอง แล้วยิงธนูใส่มัน (กด Space)", _golden_deer.global_position
	)


func _process(_delta: float) -> void:
	# ponytail: re-poke the quest marker each frame while chasing the deer so
	# it tracks the deer's live position instead of where it was when the
	# quest text was first set
	if not _abduction_started and is_instance_valid(_golden_deer) and _golden_deer.visible:
		Quest.target_position = _golden_deer.global_position


func _on_deer_defeated() -> void:
	if _abduction_started:
		return
	_abduction_started = true
	GameState.chapter_2_deer_defeated = true
	_abduction_cutscene.finished.connect(_on_abduction_finished, CONNECT_ONE_SHOT)
	_abduction_cutscene.call("show_cutscene")


func _on_abduction_finished() -> void:
	_sida.queue_free()
	_chapter3_portal.set_locked(false)
	Quest.set_quest(
		"ตามรอยทศกัณฐ์", "เดินทางออกจากป่าเพื่อตามหานางสีดา", _chapter3_portal.global_position
	)
