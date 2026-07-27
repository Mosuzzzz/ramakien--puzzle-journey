extends Node2D

const GameState := preload("res://scenes/core/game_state.gd")

func _ready() -> void:
	# set the quest for the current phase every time the plaza loads, so it
	# is correct after returning from the throne room (or a save load)
	if GameState.chapter_1_audience_done:
		var door_south := $YSortRoot/door_south as Node2D
		Quest.set_quest(
			"ออกเดินทางสู่ป่า",
			"ออกทางประตูทิศใต้ของกรุงอโยธยาเพื่อเริ่มการเดินทาง",
			door_south.global_position
		)
	else:
		var throne_room_portal := $YSortRoot/ThroneRoomPortal as Node2D
		Quest.set_quest(
			"เข้าเฝ้าท้าวทศรถ",
			"ไปยังท้องพระโรงเพื่อเข้าเฝ้าพระบิดา",
			throne_room_portal.global_position
		)
