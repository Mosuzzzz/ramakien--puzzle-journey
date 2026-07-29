extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
const KEY_FRAGMENT_PICKUP := preload("res://scenes/props/key_fragment_pickup.tscn")
const YAK_FRAGMENT_TEXTURE := preload(
	"res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png"
)

const SHAFT_FRAGMENT_ID := "lanka_key_fragment_shaft"
const YAK_AUTHORED_POSITION := Vector2(724, 445)

var _quest_started := false

@onready var _y_sort_root: Node2D = $YSortRoot
@onready var _yak: CharacterBody2D = $YSortRoot/YakCaptain
@onready var _chapter_7_portal: Area2D = $YSortRoot/Chapter7Portal


func _ready() -> void:
	var inventory := _inventory()
	if inventory != null and not inventory.changed.is_connected(_refresh_quest):
		inventory.changed.connect(_refresh_quest)
	if inventory != null and not inventory.changed.is_connected(_refresh_city_gate):
		inventory.changed.connect(_refresh_city_gate)
	if not _chapter_7_portal.activated.is_connected(_on_chapter_7_portal_activated):
		_chapter_7_portal.activated.connect(_on_chapter_7_portal_activated)
	_refresh_city_gate()

	var shaft_collected := _fragment_count(SHAFT_FRAGMENT_ID) > 0
	if shaft_collected:
		GameState.chapter_6_yak_defeated = true
		GameState.chapter_6_yak_fragment_position = Vector2.INF

	if GameState.chapter_6_yak_defeated:
		_yak.queue_free()
		if not shaft_collected:
			var restored_position := GameState.chapter_6_yak_fragment_position
			if not restored_position.is_finite():
				restored_position = YAK_AUTHORED_POSITION
			call_deferred("_spawn_yak_fragment", restored_position)
	else:
		_yak.defeated.connect(_on_yak_defeated)

	if GameState.chapter_6_intro_played:
		call_deferred("start_key_fragment_quest")


func start_key_fragment_quest() -> void:
	_quest_started = true
	_refresh_quest()


func _on_yak_defeated(defeated_yak: CharacterBody2D) -> void:
	if GameState.chapter_6_yak_defeated:
		return
	GameState.chapter_6_yak_defeated = true
	GameState.chapter_6_yak_fragment_position = defeated_yak.global_position
	_spawn_yak_fragment(defeated_yak.global_position)


func _spawn_yak_fragment(world_position: Vector2) -> void:
	if _fragment_count(SHAFT_FRAGMENT_ID) > 0:
		return
	if _y_sort_root.get_node_or_null("YakKeyFragmentPickup") != null:
		return
	var pickup := KEY_FRAGMENT_PICKUP.instantiate() as Area2D
	pickup.name = "YakKeyFragmentPickup"
	pickup.configure(
		SHAFT_FRAGMENT_ID,
		YAK_FRAGMENT_TEXTURE,
		"กด E เพื่อเก็บชิ้นส่วนกุญแจ"
	)
	pickup.collection_requested.connect(_on_fragment_collection_requested)
	_y_sort_root.add_child(pickup)
	pickup.global_position = world_position


func _on_fragment_collection_requested(pickup: Area2D) -> void:
	var inventory := _inventory()
	if inventory == null or _fragment_count(SHAFT_FRAGMENT_ID) > 0:
		return
	inventory.add_item(SHAFT_FRAGMENT_ID)
	GameState.chapter_6_yak_fragment_position = Vector2.INF
	pickup.queue_free()


func _refresh_quest() -> void:
	if _quest_started:
		Chapter6KeyQuest.refresh(get_tree())


func _refresh_city_gate() -> void:
	var unlocked := (
		GameState.chapter_6_gate_unlocked
		or Chapter6KeyQuest.has_all_fragments(get_tree())
	)
	_chapter_7_portal.set_locked(not unlocked)


func _on_chapter_7_portal_activated(_portal: Area2D) -> void:
	if GameState.chapter_6_gate_unlocked:
		return
	if not Chapter6KeyQuest.has_all_fragments(get_tree()):
		_chapter_7_portal.set_locked(true)
		return
	GameState.chapter_6_gate_unlocked = true
	if not Chapter6KeyQuest.consume_fragments(get_tree()):
		GameState.chapter_6_gate_unlocked = false
		_chapter_7_portal.set_locked(true)
		return
	Chapter6KeyQuest.refresh(get_tree())


func _fragment_count(item_id: String) -> int:
	var inventory := _inventory()
	return int(inventory.count(item_id)) if inventory != null else 0


func _inventory() -> Node:
	return get_tree().root.get_node_or_null("Inv")
