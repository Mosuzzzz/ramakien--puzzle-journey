extends Control

const CutsceneSkip := preload("res://scenes/ui/cutscene_skip.gd")

# used when the deer is felled by an arrow (map 1's escape-shot path)
const ARROW_OPENING: Array[String] = [
	"คำบรรยาย: พระรามไล่ตามกวางทองเข้าไปในป่าลึกอย่างไม่ลดละ",
	"คำบรรยาย: ทันใดนั้น กวางทองก็ผงะหันมาพร้อมแปรเปลี่ยนร่างกลายเป็นยักษ์มารีศ พระรามชะงักด้วยความตกใจ ก่อนจะน้าวศรยิงออกไปโดยพลัน",
	"มารีศ: “พระลักษมณ์... ช่วยพี่ด้วย!”",
	"คำบรรยาย: มารีศร้องเลียนเสียงพระรามเป็นครั้งสุดท้าย ก่อนจะสิ้นใจกลางป่า",
]

# one image per ARROW_OPENING line
const ARROW_IMAGES: Array[Texture2D] = [
	preload("res://assets/cutscene/chapter_2/deer_chase.png"),
	preload("res://assets/cutscene/chapter_2/deer_reaction.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
]

# used when the deer is finally cornered after the chase (map 2's quiz path)
const CATCH_OPENING: Array[String] = [
	"คำบรรยาย: พระรามไล่ตามจนในที่สุดก็เข้าใกล้กวางทองได้สำเร็จ",
	"พระราม: “ในที่สุด... เจ้าก็หนีไปไม่พ้นแล้ว!”",
	"คำบรรยาย: แต่ทันใดนั้น ร่างของกวางทองก็เรืองแสงและแปรเปลี่ยนกลายเป็นยักษ์ตนหนึ่งต่อหน้าต่อตา",
	"พระราม: “นี่มัน... ไม่ใช่กวางธรรมดา!”",
	"คำบรรยาย: พระรามตกใจ แต่ตั้งสติได้ทันที รีบน้าวศรและยิงออกไปโดยพลัน",
	"มารีศ: “ฮ่า ฮ่า ฮ่า! เจ้าคิดว่าจะเอาชนะข้าได้ง่าย ๆ อย่างนั้นหรือ พระราม!”",
	"พระราม: “เจ้าคือใครกันแน่?”",
	"มารีศ: “ข้าคือมารีศ ผู้รับใช้ทศกัณฐ์แห่งกรุงลงกา!”",
	"มารีศ: “พระลักษมณ์... ช่วยพี่ด้วย!”",
	"คำบรรยาย: มารีศร้องเลียนเสียงพระรามเป็นครั้งสุดท้าย ก่อนจะสิ้นใจกลางป่า",
]

# one image per CATCH_OPENING line
const CATCH_IMAGES: Array[Texture2D] = [
	preload("res://assets/cutscene/chapter_2/deer_chase.png"),
	preload("res://assets/cutscene/chapter_2/deer_chase.png"),
	preload("res://assets/cutscene/chapter_2/deer_reaction.png"),
	preload("res://assets/cutscene/chapter_2/deer_reaction.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
	preload("res://assets/cutscene/chapter_2/deer_death.png"),
]

const SHARED_TAIL: Array[String] = [
	"คำบรรยาย: ที่อาศรม นางสีดาได้ยินเสียงร้องนั้นก็ตกใจ เชื่อว่าพระรามกำลังตกอยู่ในอันตราย",
	"นางสีดา: “พระลักษมณ์! นั่นเสียงพระราม รีบไปช่วยท่านเถิด!”",
	"พระลักษมณ์: “พี่นางอย่าเพิ่งตกใจไป นี่อาจเป็นกลอุบายของเหล่ายักษ์ก็ได้ พี่รามท่านเก่งกาจ คงไม่เป็นไรดอก”",
	"นางสีดา: “ข้าขอร้อง พระลักษมณ์ หากท่านไม่ไป ข้าจะไปเอง!”",
	"คำบรรยาย: พระลักษมณ์จำใจต้องออกจากอาศรมไปตามหาพี่ชาย ทิ้งนางสีดาไว้เพียงลำพัง",
	"คำบรรยาย: ไม่นานนัก มีฤๅษีชรารูปหนึ่งเดินเข้ามาที่อาศรม ขอน้ำและอาหารประทังชีวิต",
	"นางสีดา: “เชิญท่านฤๅษีพักที่นี่ก่อนเถิด หม่อมฉันจะจัดหาอาหารมาถวาย”",
	"คำบรรยาย: ทันทีที่นางสีดาเข้าใกล้ ฤๅษีชราก็เผยร่างที่แท้จริง คือทศกัณฐ์ เจ้ากรุงลงกา",
	"ทศกัณฐ์: “นางสีดา... ในที่สุดข้าก็พบเจ้า เจ้าจะได้เป็นมเหสีของข้าที่กรุงลงกา!”",
	"คำบรรยาย: ทศกัณฐ์ใช้ฤทธิ์อุ้มนางสีดาขึ้นราชรถเหาะ มุ่งหน้าสู่กรุงลงกาทันที",
	"คำบรรยาย: เมื่อพระรามและพระลักษมณ์กลับมาถึงอาศรม กลับพบเพียงความว่างเปล่าและร่องรอยการต่อสู้",
	"พระราม: “สีดา... เครื่องประดับของเจ้าตกอยู่ตรงนี้... ข้าจะต้องช่วยเจ้ากลับคืนมาให้ได้”",
	"คำบรรยาย: พระรามและพระลักษมณ์จึงออกเดินทางตามรอยทศกัณฐ์ทันที มุ่งหน้าสู่การผจญภัยครั้งใหม่...",
]

# one image per SHARED_TAIL line
const SHARED_TAIL_IMAGES: Array[Texture2D] = [
	preload("res://assets/cutscene/chapter_2/sida_hears_cry.png"),
	preload("res://assets/cutscene/chapter_2/sida_hears_cry.png"),
	preload("res://assets/cutscene/chapter_2/sida_hears_cry.png"),
	preload("res://assets/cutscene/chapter_2/sida_hears_cry.png"),
	preload("res://assets/cutscene/chapter_2/lakshmana_leaves.png"),
	preload("res://assets/cutscene/chapter_2/rishi_arrives.png"),
	preload("res://assets/cutscene/chapter_2/rishi_arrives.png"),
	preload("res://assets/cutscene/chapter_2/thodsakanShow.png"),
	preload("res://assets/cutscene/chapter_2/thodsakanShow.png"),
	preload("res://assets/cutscene/chapter_2/ravana_abduction.png"),
	preload("res://assets/cutscene/chapter_2/empty_ashram.png"),
	preload("res://assets/cutscene/chapter_2/empty_ashram.png"),
	preload("res://assets/cutscene/chapter_2/empty_ashram.png"),
]

signal finished

var _active := false
var _dialogue_index := 0
var _transitioning := false
var _dialogues: Array[String] = []
var _images: Array[Texture2D] = []

@onready var _cutscene_image: TextureRect = get_node_or_null("CutsceneImage")
@onready var _background_dim: ColorRect = $BackgroundDim
@onready var _title_banner: NinePatchRect = $TitleBanner
@onready var _dialogue_label: Label = $Dialogue
@onready var _prompt_label: Label = $ContinuePrompt
@onready var _fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	hide()
	CutsceneSkip.attach(self, _finish_cutscene)


## catch_method: "arrow" (shot dead) or "catch" (cornered after the chase)
func show_cutscene(catch_method: String = "arrow") -> void:
	_dialogues = (ARROW_OPENING if catch_method == "arrow" else CATCH_OPENING) + SHARED_TAIL
	_images = (ARROW_IMAGES if catch_method == "arrow" else CATCH_IMAGES) + SHARED_TAIL_IMAGES
	_active = true
	_transitioning = true
	_dialogue_index = 0
	_show_dialogue(0, false)
	var content: Array[CanvasItem] = [_background_dim, _title_banner, _dialogue_label, _prompt_label]
	if not _images.is_empty() and _cutscene_image:
		content.append(_cutscene_image)
	elif _cutscene_image:
		_cutscene_image.hide()
	for item: CanvasItem in content:
		item.hide()
	_fade_overlay.color.a = 0.0
	show()
	get_tree().paused = true
	_play_intro_transition(content)


func _play_intro_transition(content: Array[CanvasItem]) -> void:
	var darken := create_tween()
	darken.tween_property(_fade_overlay, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	await darken.finished
	for item: CanvasItem in content:
		item.show()
	var reveal := create_tween()
	reveal.tween_property(_fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	_transitioning = false


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouse:
		return  # let the GUI (skip button) receive clicks; the tree is paused anyway
	get_viewport().set_input_as_handled()
	if _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_advance_dialogue()


func _advance_dialogue() -> void:
	if _dialogue_index + 1 >= _dialogues.size():
		_finish_cutscene()
	else:
		_show_dialogue(_dialogue_index + 1, true)


func _show_dialogue(index: int, animated: bool) -> void:
	_dialogue_index = index
	if _cutscene_image:
		if index < _images.size():
			_cutscene_image.texture = _images[index]
			_cutscene_image.show()
		else:
			_cutscene_image.hide()
	_prompt_label.text = "กด E เพื่อออกติดตามทศกัณฐ์ ▼" if index == _dialogues.size() - 1 else "กด E เพื่อดำเนินเรื่องต่อ ▼"
	if not animated:
		_dialogue_label.text = _dialogues[_dialogue_index]
		return

	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_dialogue_label, "modulate:a", 0.0, 0.12)
	await fade_out.finished
	_dialogue_label.text = _dialogues[_dialogue_index]
	var fade_in := create_tween()
	fade_in.tween_property(_dialogue_label, "modulate:a", 1.0, 0.18)
	await fade_in.finished
	_transitioning = false


func _finish_cutscene() -> void:
	_active = false
	hide()
	get_tree().paused = false
	finished.emit()


func _exit_tree() -> void:
	if _active and get_tree() != null:
		get_tree().paused = false
