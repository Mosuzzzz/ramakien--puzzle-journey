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


## Fade to black, run the skip, then fade back in. The shade lives on the tree
## root so it survives the cutscene being freed or the scene changing.
static func _skip_with_fade(b: Button, on_skip: Callable) -> void:
	b.disabled = true
	var tree := b.get_tree()
	var layer := CanvasLayer.new()
	layer.layer = 999
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	tree.root.add_child(layer)
	var fade_out := layer.create_tween()
	fade_out.tween_property(shade, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	on_skip.call()
	await tree.process_frame
	await tree.process_frame
	var fade_in := layer.create_tween()
	fade_in.tween_property(shade, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await fade_in.finished
	layer.queue_free()
