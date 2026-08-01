extends CanvasLayer

signal changed

# ponytail: one flat catalog + count dict; real item classes when items get behavior
const ITEMS := {
	"potion": {"name": "ยารักษา", "icon": "res://assets/ui/icon/split/icon_potion_red.png"},
	"potion_blue": {"name": "ยาวิเศษ", "icon": "res://assets/ui/icon/split/icon_potion_blue.png"},
	"key": {"name": "กุญแจ", "icon": "res://assets/ui/icon/split/icon_key.png"},
	"coin": {"name": "เหรียญ", "icon": "res://assets/ui/icon/split/icon_coin.png"},
	"gem": {"name": "อัญมณี", "icon": "res://assets/ui/icon/split/icon_gem.png"},
	"jatayu_feather": {
		"name": "ขนนกพญาชฎายุ",
		"icon": "res://assets/ui/icon/split/icon_wing.png",
	},
	"lanka_key_fragment_shaft": {
		"name": "ชิ้นส่วนกุญแจ: แกน",
		"icon": "res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png",
	},
	"lanka_key_fragment_bar": {
		"name": "ชิ้นส่วนกุญแจ: แท่ง",
		"icon": "res://assets/ui/icon/split/image-removebg-preview สำเนา.png",
	},
	"lanka_key_fragment_ring": {
		"name": "ชิ้นส่วนกุญแจ: ห่วง",
		"icon": "res://assets/ui/icon/split/image-removebg-preview.png",
	},
}

var items := {"potion": 3}

@onready var _bag: TextureButton = $BagButton
@onready var _page: Control = $PageDim
@onready var _grid: GridContainer = $PageDim/Page/PageMargin/Grid

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_page.hide()

func set_hud_visible(shown: bool) -> void:
	_bag.visible = shown
	if not shown:
		_page.hide()

func count(id: String) -> int:
	return int(items.get(id, 0))

func get_items_snapshot() -> Dictionary:
	return items.duplicate(true)

func restore_items(snapshot: Dictionary) -> void:
	items = snapshot.duplicate(true)
	changed.emit()
	if is_instance_valid(_page) and _page.visible:
		_refresh()

func reset_for_new_story() -> void:
	items = {"potion": 3}
	changed.emit()
	if is_instance_valid(_page) and _page.visible:
		_refresh()

func add_item(id: String, n: int = 1) -> void:
	items[id] = count(id) + n
	AudioManager.play_sfx(AudioManager.PICKUP)
	changed.emit()

func remove_item(id: String, n: int = 1) -> bool:
	if count(id) < n:
		return false
	items[id] -= n
	if items[id] <= 0:
		items.erase(id)
	changed.emit()
	return true

func _on_bag_pressed() -> void:
	_page.visible = not _page.visible
	if _page.visible:
		_refresh()

func _close_page() -> void:
	_page.hide()

func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for id in items:
		var info: Dictionary = ITEMS.get(id, {})
		var slot := VBoxContainer.new()
		slot.custom_minimum_size = Vector2(90, 0)
		var icon := TextureRect.new()
		icon.texture = load(info.get("icon", ""))
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
		var label := Label.new()
		label.text = "%s x%d" % [info.get("name", id), items[id]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.25, 0.16, 0.08))
		slot.add_child(label)
		_grid.add_child(slot)
