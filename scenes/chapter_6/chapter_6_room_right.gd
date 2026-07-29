extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
const KEY_FRAGMENT_PICKUP := preload("res://scenes/props/key_fragment_pickup.tscn")
const RING_TEXTURE := preload("res://assets/ui/icon/split/image-removebg-preview.png")

const ROOM_QUEST := "ค้นหาโค้ดลับเพื่อปลดล็อกชิ้นส่วนกุญแจ"
const PICKUP_QUEST := "เก็บชิ้นส่วนกุญแจ"
const SEARCH_PROMPT := "กด E เพื่อค้นหา"
const REVIEW_PROMPT := "กด E เพื่อดูในโหล"
const RING_ID := "lanka_key_fragment_ring"
const RING_PICKUP_POSITION := Vector2(627, 555)
const JARS := [
	{
		"index": 0,
		"question": "ข้อใดเป็นคำพ้องเสียง",
		"choices": ["การ – กาล", "บ้าน – เรือน", "สูง – ต่ำ"],
		"correct_index": 0,
		"digit": 7,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_12.png",
	},
	{
		"index": 1,
		"question": "คำว่า “เสียสละ” มีความหมายตรงกับข้อใด",
		"choices": [
			"ยอมสละประโยชน์ของตนเพื่อผู้อื่น",
			"ทำงานโดยหวังรางวัล",
			"หลีกเลี่ยงการช่วยเหลือ",
		],
		"correct_index": 0,
		"digit": -1,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_09_37.png",
	},
	{
		"index": 2,
		"question": "สำนวน “น้ำขึ้นให้รีบตัก” หมายถึงอะไร",
		"choices": [
			"ให้รีบตักน้ำเก็บไว้",
			"ให้ใช้โอกาสที่ดีให้เกิดประโยชน์",
			"ให้ทำงานอย่างช้า ๆ",
		],
		"correct_index": 1,
		"digit": 3,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_53_33.png",
	},
	{
		"index": 3,
		"question": "ข้อใดใช้คำเชื่อมได้ถูกต้อง",
		"choices": [
			"เพราะฝนตก แต่ฉันจึงกางร่ม",
			"เพราะฝนตก ฉันจึงกางร่ม",
			"แม้ฝนตก เพราะฉันกางร่ม",
		],
		"correct_index": 1,
		"digit": 2,
		"texture_path": "res://assets/ui/icon/split/ChatGPT Image 28 ก.ค. 2569 21_52_39.png",
	},
]
const JAR_NODE_NAMES := [
	"JarUpperLeft",
	"JarUpperRight",
	"JarLowerLeft",
	"JarLowerRight",
]

var _near_jar_index := -1
var _near_pedestal := false
var _modal_active := false

@onready var _jar_modal: CanvasLayer = $RightJarModal
@onready var _code_modal: CanvasLayer = $RightCodeModal
@onready var _pedestal_interaction: Area2D = $PedestalInteraction
@onready var _pedestal_prompt: Label = $PedestalInteraction/Prompt
@onready var _y_sort_root: Node2D = $YSortRoot


func _ready() -> void:
	_jar_modal.searched.connect(_on_jar_searched)
	_jar_modal.closed.connect(_on_jar_modal_closed)
	_code_modal.solved.connect(_on_code_solved)
	_code_modal.closed.connect(_on_code_modal_closed)
	_pedestal_interaction.body_entered.connect(_on_pedestal_body_entered)
	_pedestal_interaction.body_exited.connect(_on_pedestal_body_exited)
	for index: int in range(JAR_NODE_NAMES.size()):
		var area := _jar_area(index)
		area.body_entered.connect(_on_jar_body_entered.bind(index))
		area.body_exited.connect(_on_jar_body_exited.bind(index))
		_update_jar_prompt(index)
	if _ring_count() > 0:
		GameState.chapter_6_right_pedestal_solved = true
	if GameState.chapter_6_right_pedestal_solved:
		_disable_pedestal()
		if _ring_count() == 0:
			call_deferred("_spawn_ring_fragment")
			_set_room_quest(PICKUP_QUEST)
		else:
			Chapter6KeyQuest.refresh(get_tree())
	else:
		_set_room_quest(ROOM_QUEST)


func _unhandled_input(event: InputEvent) -> void:
	if _modal_active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if _near_pedestal and not GameState.chapter_6_right_pedestal_solved:
			_open_code_modal()
		elif _near_jar_index >= 0:
			_open_jar(_near_jar_index)
		else:
			return
		get_viewport().set_input_as_handled()


func _on_jar_body_entered(body: Node2D, index: int) -> void:
	if body.name != "Player":
		return
	_near_jar_index = index
	if not _modal_active:
		_update_jar_prompt(index)
		_jar_prompt(index).show()


func _on_jar_body_exited(body: Node2D, index: int) -> void:
	if body.name != "Player":
		return
	_jar_prompt(index).hide()
	if _near_jar_index == index:
		_near_jar_index = -1


func _open_jar(index: int) -> void:
	_modal_active = true
	_hide_all_jar_prompts()
	_jar_modal.open_jar(_jar_definition(index), _is_jar_searched(index))


func _on_jar_searched(index: int) -> void:
	GameState.chapter_6_right_jars_mask |= 1 << index
	_update_jar_prompt(index)


func _on_jar_modal_closed() -> void:
	_modal_active = false
	_restore_nearby_prompt()


func _is_jar_searched(index: int) -> bool:
	return (GameState.chapter_6_right_jars_mask & (1 << index)) != 0


func _jar_definition(index: int) -> Dictionary:
	var definition: Dictionary = JARS[index].duplicate(true)
	definition["result_texture"] = load(String(definition.texture_path))
	return definition


func _update_jar_prompt(index: int) -> void:
	_jar_prompt(index).text = REVIEW_PROMPT if _is_jar_searched(index) else SEARCH_PROMPT


func _hide_all_jar_prompts() -> void:
	for index: int in range(JAR_NODE_NAMES.size()):
		_jar_prompt(index).hide()


func _jar_area(index: int) -> Area2D:
	return $JarInteractions.get_node(JAR_NODE_NAMES[index]) as Area2D


func _jar_prompt(index: int) -> Label:
	return _jar_area(index).get_node("Prompt") as Label


func _on_pedestal_body_entered(body: Node2D) -> void:
	if body.name != "Player" or GameState.chapter_6_right_pedestal_solved:
		return
	_near_pedestal = true
	if not _modal_active:
		_pedestal_prompt.show()


func _on_pedestal_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near_pedestal = false
	_pedestal_prompt.hide()


func _open_code_modal() -> void:
	_modal_active = true
	_pedestal_prompt.hide()
	_hide_all_jar_prompts()
	_code_modal.open(_discovered_digits())


func _on_code_modal_closed() -> void:
	_modal_active = false
	_restore_nearby_prompt()


func _discovered_digits() -> Array[int]:
	var result: Array[int] = []
	for jar: Dictionary in JARS:
		var digit := int(jar.digit)
		if digit >= 0 and _is_jar_searched(int(jar.index)):
			result.append(digit)
	return result


func _on_code_solved() -> void:
	_modal_active = false
	if GameState.chapter_6_right_pedestal_solved:
		return
	GameState.chapter_6_right_pedestal_solved = true
	_disable_pedestal()
	_set_room_quest(PICKUP_QUEST)
	_spawn_ring_fragment()


func _disable_pedestal() -> void:
	_near_pedestal = false
	_pedestal_prompt.hide()
	_pedestal_interaction.set_deferred("monitoring", false)
	_pedestal_interaction.set_deferred("monitorable", false)


func _spawn_ring_fragment() -> void:
	if _ring_count() > 0 or _y_sort_root.get_node_or_null("RightRoomKeyFragment") != null:
		return
	var pickup := KEY_FRAGMENT_PICKUP.instantiate() as Area2D
	pickup.name = "RightRoomKeyFragment"
	pickup.configure(RING_ID, RING_TEXTURE, "กด E เพื่อเก็บชิ้นส่วนกุญแจ")
	pickup.collection_requested.connect(_on_ring_collection_requested)
	_y_sort_root.add_child(pickup)
	pickup.global_position = RING_PICKUP_POSITION


func _on_ring_collection_requested(pickup: Area2D) -> void:
	var inventory := _inventory()
	if inventory != null and _ring_count() == 0:
		inventory.add_item(RING_ID)
		Chapter6KeyQuest.refresh(get_tree())
	pickup.queue_free()


func _ring_count() -> int:
	var inventory := _inventory()
	return int(inventory.count(RING_ID)) if inventory != null else 0


func _inventory() -> Node:
	return get_tree().root.get_node_or_null("Inv")


func _set_room_quest(name: String) -> void:
	var quest := get_tree().root.get_node_or_null("Quest")
	if quest != null:
		quest.set_quest(name, "")
		quest.set_completed(false)


func _restore_nearby_prompt() -> void:
	if _near_pedestal and not GameState.chapter_6_right_pedestal_solved:
		_pedestal_prompt.show()
	elif _near_jar_index >= 0:
		_update_jar_prompt(_near_jar_index)
		_jar_prompt(_near_jar_index).show()
