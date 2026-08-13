extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")

const MAP_WIDTH := 1881.0
const PATH_Y := 398.0
const ASHRAM_RETURN_SPAWN := Vector2(1120, 680)

# the scripted chase: the deer always stays _gap px ahead of the player.
# running alone never closes the distance — only correct answers do.
const START_GAP := 620.0
const CATCH_GAP := 80.0
const CORRECT_GAP_STEP := 180.0
const WRONG_GAP_STEP := 150.0
const QUESTION_INTERVAL := 4.0

const FAIL_LINES: Array[String] = [
	"กวางทองวิ่งลับหายไปในป่าลึก ไม่อาจตามต่อได้ทัน",
	"พระรามและพระลักษมณ์จำต้องถอยกลับไปยังอาศรมก่อน...",
]

# [question, choices, correct index] — each one is only asked once per chase
const QUESTIONS := [
	["คำราชาศัพท์ของคำว่า “จมูก” คือข้อใด?", ["พระนาสิก", "พระโอษฐ์", "พระปราง"], 0],
	["คำราชาศัพท์ของคำว่า “ผม (เส้นผม)” คือข้อใด?", ["พระเกศา", "พระศอ", "พระพักตร์"], 0],
	["“พระโอษฐ์” หมายถึงอวัยวะใด?", ["ปาก", "คิ้ว", "ฟัน"], 0],
	["“พระทนต์” หมายถึงสิ่งใด?", ["ฟัน", "เล็บ", "ผิวหนัง"], 0],
	["คำราชาศัพท์ของคำว่า “แขน” คือข้อใด?", ["พระกร", "พระชานุ", "พระอุระ"], 0],
	["“พระอุระ” หมายถึงอวัยวะใดในร่างกาย?", ["หน้าอก", "หลัง", "ท้อง"], 0],
	["คำราชาศัพท์ของคำว่า “หน้าผาก” คือข้อใด?", ["พระนลาฏ", "พระขนง", "พระพักตร์"], 0],
	["“พระปราง” หมายถึงส่วนใดของใบหน้า?", ["แก้ม", "คาง", "หน้าผาก"], 0],
	["คำราชาศัพท์ของคำว่า “คอ” คือข้อใด?", ["พระศอ", "พระหนุ", "พระอังสา"], 0],
	["“พระอังสา” หมายถึงอวัยวะใด?", ["บ่า, ไหล่", "ข้อศอก", "ข้อมือ"], 0],
	["คำราชาศัพท์ของคำว่า “สะดือ” คือข้อใด?", ["พระนาภี", "พระกฤษฎี", "พระพาหา"], 0],
	["“พระชานุ” หมายถึงอวัยวะใด?", ["เข่า", "นิ้วเท้า", "หน้าแข้ง"], 0],
]

var _abduction_started := false
var _failed := false
var _quiz_open := false
var _gap := START_GAP
var _question_timer := 0.0
var _question_queue: Array = []

@onready var _golden_deer: CharacterBody2D = $YSortRoot/GoldenDeer
@onready var _player: CharacterBody2D = $YSortRoot/Player
@onready var _quiz: CanvasLayer = $QuestionQuiz
@onready var _abduction_cutscene: Control = $Chapter2AbductionCutsceneLayer/AbductionCutscene
@onready var _return_portal := $YSortRoot/ReturnPortal


func _ready() -> void:
	# the looping path is meant to feel endless — a minimap would give it away
	var minimap := _player.get_node_or_null("HUD/MiniMap")
	if minimap != null:
		minimap.hide()
	if GameState.chapter_2_deer_defeated:
		_golden_deer.queue_free()
		_return_portal.set_locked(false)
		return
	_quiz.answered.connect(_on_quiz_answered)
	_question_queue = range(QUESTIONS.size())
	_question_queue.shuffle()
	# this chase is fully scripted: WASD/arrows are disabled, the player only
	# acts through the quiz — the deer's distance is driven by _gap, not by
	# actually out-walking it
	_player.movement_locked = true
	_player.auto_run_velocity = Vector2(_player.speed, 0.0)
	# the chase is scripted: this script drives the deer, not its own AI
	_golden_deer.set_physics_process(false)
	_golden_deer.set("_face_right", true)
	_golden_deer.call("_play", "run")
	Quest.set_quest(
		"ไล่ตามกวางทอง",
		"กวางทองวิ่งเร็วเกินกว่าจะไล่ทัน จงตอบคำถามให้ถูกเพื่อเข้าใกล้มันทีละก้าว",
		_golden_deer.global_position
	)


func _physics_process(_delta: float) -> void:
	# the path loops: crossing one edge continues from the other side
	if _player.global_position.x > MAP_WIDTH or _player.global_position.x < 0.0:
		_player.global_position.x = wrapf(_player.global_position.x, 0.0, MAP_WIDTH)
		var camera := _player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.reset_smoothing()
	if _abduction_started or _failed or not is_instance_valid(_golden_deer):
		return
	# no wrap here: player.x is already kept within [0, MAP_WIDTH) above, and
	# the tiled background art extends a full map-width past each edge, so
	# player.x + _gap stays within the rendered range and the deer never
	# needs to jump — wrapping this would snap it visually behind the player
	# every time the sum crossed MAP_WIDTH
	_golden_deer.global_position = Vector2(_player.global_position.x + _gap, PATH_Y)


func _process(delta: float) -> void:
	if _abduction_started or _failed or _quiz_open or not is_instance_valid(_golden_deer):
		return
	Quest.target_position = _golden_deer.global_position
	_question_timer += delta
	if _question_timer >= QUESTION_INTERVAL:
		_question_timer = 0.0
		if _question_queue.is_empty():
			_fail_chase()
			return
		_quiz_open = true
		var q: Array = QUESTIONS[_question_queue.pop_front()]
		_quiz.call("ask", q[0], q[1], q[2])


func _on_quiz_answered(correct: bool) -> void:
	_quiz_open = false
	if correct:
		_gap -= CORRECT_GAP_STEP
		if _gap <= CATCH_GAP:
			_catch_deer()
	else:
		_gap += WRONG_GAP_STEP


func _catch_deer() -> void:
	if _abduction_started:
		return
	_abduction_started = true
	GameState.chapter_2_deer_defeated = true
	_player.auto_run_velocity = Vector2.ZERO
	_player.movement_locked = false
	_golden_deer.queue_free()
	Quest.clear()
	_abduction_cutscene.finished.connect(_on_abduction_finished, CONNECT_ONE_SHOT)
	_abduction_cutscene.call("show_cutscene", "catch")


func _on_abduction_finished() -> void:
	# Return to the ashram automatically after the deer/abduction story ends.
	GameState.next_spawn = ASHRAM_RETURN_SPAWN
	GameState.next_health = _player.current_health
	# The cutscene emits `finished` from inside its closing fade callback, while
	# SceneTransition is still busy. Wait for that fade to release its lock so
	# change_chapter is not rejected with ERR_BUSY.
	while SceneTransition.is_busy():
		await get_tree().process_frame
	await SceneTransition.change_chapter("res://scenes/chapter_2/chapter_2.tscn")


func _fail_chase() -> void:
	_failed = true
	_player.auto_run_velocity = Vector2.ZERO
	_player.movement_locked = false
	_return_portal.set_locked(false)
	if is_instance_valid(_golden_deer):
		_golden_deer.queue_free()
	Quest.clear()
	Dialogue.finished.connect(_on_fail_finished, CONNECT_ONE_SHOT)
	Dialogue.start_narration(FAIL_LINES, "พลาดกวางทอง")


func _on_fail_finished() -> void:
	GameState.next_spawn = ASHRAM_RETURN_SPAWN
	GameState.next_health = _player.current_health
	await SceneTransition.change_chapter("res://scenes/chapter_2/chapter_2.tscn")


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.auto_run_velocity = Vector2.ZERO
		_player.movement_locked = false
