extends RefCounted

const GameState := preload("res://scenes/core/game_state.gd")

const SHAFT_FRAGMENT_ID := "lanka_key_fragment_shaft"
const BAR_FRAGMENT_ID := "lanka_key_fragment_bar"
const RING_FRAGMENT_ID := "lanka_key_fragment_ring"
const FRAGMENT_IDS := [SHAFT_FRAGMENT_ID, BAR_FRAGMENT_ID, RING_FRAGMENT_ID]
const QUEST_NAME := "ตามหาชิ้นส่วนกุญแจให้ครบเพื่อปลดล็อกประตูเมือง"
const QUEST_DETAIL := "รวบรวมชิ้นส่วนกุญแจ %d/3"
const GATE_READY_DETAIL := "รวบรวมชิ้นส่วนกุญแจ 3/3 — ไปปลดล็อกประตูเมือง"
const GATE_OPEN_DETAIL := "ประตูเมืองถูกปลดล็อกแล้ว"


static func progress(tree: SceneTree) -> int:
	var inventory := tree.root.get_node_or_null("Inv")
	if inventory == null:
		return 0
	var total := 0
	for item_id: String in FRAGMENT_IDS:
		total += mini(int(inventory.count(item_id)), 1)
	return total


static func has_all_fragments(tree: SceneTree) -> bool:
	return progress(tree) == FRAGMENT_IDS.size()


static func consume_fragments(tree: SceneTree) -> bool:
	if not has_all_fragments(tree):
		return false
	var inventory := tree.root.get_node_or_null("Inv")
	if inventory == null:
		return false
	for item_id: String in FRAGMENT_IDS:
		inventory.remove_item(item_id)
	return true


static func refresh(tree: SceneTree) -> int:
	var total := progress(tree)
	var quest := tree.root.get_node_or_null("Quest")
	if quest != null:
		if GameState.chapter_6_gate_unlocked:
			quest.set_quest(QUEST_NAME, GATE_OPEN_DETAIL)
			quest.set_completed(true)
		elif total >= FRAGMENT_IDS.size():
			quest.set_quest(QUEST_NAME, GATE_READY_DETAIL)
			quest.set_completed(true)
		else:
			quest.set_quest(QUEST_NAME, QUEST_DETAIL % total)
			quest.set_completed(false)
	return total
