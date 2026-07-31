extends Object


static func is_advance_event(event: InputEvent, hovered_control: Control) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == KEY_E
	if event is InputEventMouseButton:
		return (
			event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT
			and not hovered_control is Button
		)
	return false


static func consume_advance_event(event: InputEvent, hovered_control: Control) -> bool:
	if not is_advance_event(event, hovered_control):
		return false
	var audio_manager: Node = Engine.get_main_loop().root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx(&"button_click")
	return true
