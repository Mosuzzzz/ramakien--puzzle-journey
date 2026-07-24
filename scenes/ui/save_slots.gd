extends CanvasLayer

const SaveGame := preload("res://scenes/save_game.gd")

var _mode := "save"

@onready var _dim: Control = $Dim
@onready var _title: Label = $Dim/Panel/VBox/Title
@onready var _slot_rows: Array = [
	$Dim/Panel/VBox/Slot0, $Dim/Panel/VBox/Slot1, $Dim/Panel/VBox/Slot2
]


func _ready() -> void:
	_dim.visible = false
	for slot in range(_slot_rows.size()):
		(_slot_rows[slot] as Button).pressed.connect(_on_slot_pressed.bind(slot))


## mode: "save" or "load"
func open(mode: String) -> void:
	_mode = mode
	_title.text = "บันทึกเกม" if mode == "save" else "โหลดเกม"
	for slot in range(_slot_rows.size()):
		var info := SaveGame.slot_info(slot)
		var row := _slot_rows[slot] as Button
		if info.exists:
			row.text = "ช่อง %d — %s (%s)" % [slot + 1, info.chapter_name, info.timestamp]
		else:
			row.text = "ช่อง %d — ว่าง" % [slot + 1]
	_dim.visible = true
	get_tree().paused = true


func _close() -> void:
	_dim.visible = false
	# if PauseMenu was open underneath us, stay paused and return to it
	# instead of resuming gameplay
	get_tree().paused = PauseMenu.is_open()


func _on_slot_pressed(slot: int) -> void:
	if _mode == "save":
		SaveGame.save_to_slot(slot)
		open(_mode)  # refresh the row labels to show the new save
		return
	if not SaveGame.slot_info(slot).exists:
		return
	_dim.visible = false
	# loading leaves this context entirely — force-unpause and drop the
	# pause menu too, since both are autoloads that'd otherwise persist
	# as a stuck overlay on the newly loaded scene
	PauseMenu.force_close()
	SaveGame.load_slot(slot)


func _on_close_pressed() -> void:
	_close()
