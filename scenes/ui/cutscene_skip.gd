extends Object

## Shared factory: adds a themed "ข้าม »" button (top-right) that calls on_skip.
static func attach(host: Node, on_skip: Callable) -> Button:
	var b := Button.new()
	b.name = "SkipButton"
	b.text = "ข้าม »"
	b.add_theme_font_override("font", load("res://assets/fonts/Sarabun-Bold.ttf"))
	b.add_theme_font_size_override("font_size", 20)
	b.flat = true
	b.add_theme_color_override("font_outline_color", Color.BLACK)
	b.add_theme_constant_override("outline_size", 6)
	b.pressed.connect(_skip_with_fade.bind(b, on_skip))
	var parent: Node = host
	if not (host is Control):
		# ponytail: world scenes (Node2D) need a CanvasLayer for screen-space UI
		var layer := CanvasLayer.new()
		layer.layer = 100
		host.add_child(layer)
		parent = layer
	parent.add_child(b)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -204.0
	b.offset_top = 16.0
	b.offset_right = -80.0
	b.offset_bottom = 62.0
	return b


## Delegate the visual transition to the cutscene's normal finish path so skip
## and accepted advance use the same shared fade sequence.
static func _skip_with_fade(b: Button, on_skip: Callable) -> void:
	var transition := b.get_node_or_null("/root/SceneTransition")
	if b.disabled or (transition != null and transition.is_busy()):
		return
	b.disabled = true
	on_skip.call()
