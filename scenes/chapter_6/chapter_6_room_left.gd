extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")
const Chapter6KeyQuest := preload("res://scenes/chapter_6/chapter_6_key_quest.gd")
const KEY_FRAGMENT_PICKUP := preload("res://scenes/props/key_fragment_pickup.tscn")
const BAR_TEXTURE := preload("res://assets/ui/icon/split/image-removebg-preview สำเนา.png")
const BAR_ID := "lanka_key_fragment_bar"
const PICKUP_POSITION := Vector2(315, 365)

var _player_near := false
var _opening := false

@onready var _interaction: Area2D = $ChestInteraction
@onready var _prompt: Label = $ChestInteraction/ChestPrompt
@onready var _puzzle: CanvasLayer = $LeftChestPuzzle
@onready var _y_sort_root: Node2D = $YSortRoot


func _ready() -> void:
	_interaction.body_entered.connect(_on_chest_body_entered)
	_interaction.body_exited.connect(_on_chest_body_exited)
	_puzzle.solved.connect(_on_chest_puzzle_solved)
	_puzzle.cancelled.connect(_on_chest_puzzle_cancelled)
	if _bar_count() > 0:
		GameState.chapter_6_left_chest_unlocked = true
	if GameState.chapter_6_left_chest_unlocked:
		_disable_chest_interaction()
		if _bar_count() == 0:
			call_deferred("_spawn_fragment")
	if GameState.chapter_6_intro_played:
		Chapter6KeyQuest.refresh(get_tree())


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or _opening or GameState.chapter_6_left_chest_unlocked:
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_opening = true
		_prompt.hide()
		_puzzle.open()
		get_viewport().set_input_as_handled()


func _on_chest_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not GameState.chapter_6_left_chest_unlocked:
		_player_near = true
		_prompt.show()


func _on_chest_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_near = false
		_prompt.hide()


func _on_chest_puzzle_solved() -> void:
	if GameState.chapter_6_left_chest_unlocked:
		return
	GameState.chapter_6_left_chest_unlocked = true
	_opening = false
	_disable_chest_interaction()
	_spawn_fragment()


func _on_chest_puzzle_cancelled() -> void:
	_opening = false
	if _player_near and not GameState.chapter_6_left_chest_unlocked:
		_prompt.show()


func _disable_chest_interaction() -> void:
	_player_near = false
	_prompt.hide()
	_interaction.set_deferred("monitoring", false)
	_interaction.set_deferred("monitorable", false)


func _spawn_fragment() -> void:
	if _bar_count() > 0 or _y_sort_root.get_node_or_null("LeftChestKeyFragment") != null:
		return
	var pickup := KEY_FRAGMENT_PICKUP.instantiate() as Area2D
	pickup.name = "LeftChestKeyFragment"
	pickup.configure(BAR_ID, BAR_TEXTURE, "กด E เพื่อเก็บชิ้นส่วนกุญแจ")
	pickup.collection_requested.connect(_on_fragment_collection_requested)
	_y_sort_root.add_child(pickup)
	pickup.global_position = PICKUP_POSITION


func _on_fragment_collection_requested(pickup: Area2D) -> void:
	var inventory := _inventory()
	if inventory != null and _bar_count() == 0:
		inventory.add_item(BAR_ID)
		Chapter6KeyQuest.refresh(get_tree())
	pickup.queue_free()


func _bar_count() -> int:
	var inventory := _inventory()
	return int(inventory.count(BAR_ID)) if inventory != null else 0


func _inventory() -> Node:
	return get_tree().root.get_node_or_null("Inv")
