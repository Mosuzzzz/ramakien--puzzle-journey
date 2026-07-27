extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/props/jatayu_feather.tscn")
	if packed == null:
		_fail("Feather scene could not be loaded")
		return
	var feather: Area2D = packed.instantiate()
	root.add_child(feather)
	await process_frame

	var sprite := feather.get_node("Wing") as Sprite2D
	var initial_y := sprite.position.y
	await create_timer(0.2).timeout
	if is_equal_approx(sprite.position.y, initial_y):
		_fail("Feather did not bob")
		return

	var requested := [false]
	feather.collection_requested.connect(func(_value: Area2D) -> void: requested[0] = true)
	var player := CharacterBody2D.new()
	player.name = "Player"
	feather.call("_on_body_entered", player)
	var interact := InputEventKey.new()
	interact.pressed = true
	interact.keycode = KEY_E
	feather.call("_unhandled_input", interact)
	if not requested[0]:
		_fail("Feather did not request collection when E was pressed nearby")
		return

	await feather.call("fade_and_relocate", Vector2(320, 240))
	if feather.global_position != Vector2(320, 240):
		_fail("Feather did not relocate after a wrong answer")
		return
	if not feather.visible or not feather.monitoring:
		_fail("Relocated feather did not become active again")
		return

	feather.call("mark_collected")
	if feather.visible or feather.monitoring:
		_fail("Collected feather remained active")
		return

	player.free()
	feather.queue_free()
	await process_frame
	print("Jatayu feather runtime passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
