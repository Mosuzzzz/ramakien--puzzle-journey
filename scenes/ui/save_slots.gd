extends CanvasLayer

const SaveGame := preload("res://scenes/save_game.gd")
const HOME_PAGE := "res://scenes/homepage/home_page.tscn"

var _mode := "save"

@onready var _dim: Control = $Dim
@onready var _title: Label = $Dim/Panel/VBox/Title
@onready var _slot_rows: Array = [
	$Dim/Panel/VBox/Row0/Slot0, $Dim/Panel/VBox/Row1/Slot1, $Dim/Panel/VBox/Row2/Slot2
]
@onready var _delete_buttons: Array = [
	$Dim/Panel/VBox/Row0/Delete0, $Dim/Panel/VBox/Row1/Delete1, $Dim/Panel/VBox/Row2/Delete2
]


func _ready() -> void:
	_dim.visible = false
	for slot in range(_slot_rows.size()):
		(_slot_rows[slot] as Button).pressed.connect(_on_slot_pressed.bind(slot))
		(_delete_buttons[slot] as Button).pressed.connect(_on_delete_pressed.bind(slot))


## mode: "save" (save & stay), "save_exit" (save then go home), or "load"
func open(mode: String) -> void:
	_mode = mode
	_title.text = "โหลดเกม" if mode == "load" else "บันทึกเกม"
	_refresh()
	_dim.visible = true
	get_tree().paused = true


func _refresh() -> void:
	for slot in range(_slot_rows.size()):
		var info := SaveGame.slot_info(slot)
		(_slot_rows[slot] as Button).text = (
			"ช่อง %d — %s (%s)" % [slot + 1, info.chapter_name, info.timestamp] if info.exists
			else "ช่อง %d — ว่าง" % [slot + 1]
		)
		# only offer delete on slots that actually hold a save
		(_delete_buttons[slot] as Button).visible = info.exists


func _close() -> void:
	_dim.visible = false
	# if PauseMenu was open underneath us, stay paused and return to it
	# instead of resuming gameplay
	get_tree().paused = PauseMenu.is_open()


func _on_slot_pressed(slot: int) -> void:
	if _mode == "load":
		if not SaveGame.slot_info(slot).exists:
			return
		_dim.visible = false
		# loading leaves this context entirely — force-unpause and drop the
		# pause menu too, since both are autoloads that'd otherwise persist
		# as a stuck overlay on the newly loaded scene
		PauseMenu.force_close()
		SaveGame.load_slot(slot)
		return

	# save modes
	SaveGame.save_to_slot(slot)
	if _mode == "save_exit":
		_dim.visible = false
		PauseMenu.force_close()
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred(HOME_PAGE)
	else:
		_refresh()  # save & stay: show the new save


func _on_delete_pressed(slot: int) -> void:
	SaveGame.delete_slot(slot)
	_refresh()


func _on_close_pressed() -> void:
	_close()
