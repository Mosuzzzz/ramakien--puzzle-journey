extends SceneTree

const PICKUP_SCENE := "res://scenes/props/key_fragment_pickup.tscn"
const SHAFT_TEXTURE := "res://assets/ui/icon/split/image-removebg-preview-removebg-preview.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mob := (load("res://scenes/props/mob.tscn") as PackedScene).instantiate()
	mob.set("max_health", 1)
	root.add_child(mob)
	if not mob.has_signal("defeated"):
		_fail("Mob has no one-shot defeated signal")
		return
	var defeat_state := {"count": 0}
	mob.connect("defeated", func(_defeated_mob: CharacterBody2D) -> void:
		defeat_state["count"] += 1
	)
	mob.call("apply_authorized_damage", 1)
	mob.call("apply_authorized_damage", 1)
	await create_timer(0.2).timeout
	if int(defeat_state["count"]) != 1:
		_fail("Lethal mob damage did not emit defeated exactly once")
		return

	if not ResourceLoader.exists(PICKUP_SCENE):
		_fail("Key fragment pickup scene does not exist")
		return
	var pickup := (load(PICKUP_SCENE) as PackedScene).instantiate() as Area2D
	pickup.call(
		"configure",
		"lanka_key_fragment_shaft",
		load(SHAFT_TEXTURE),
		"กด E เพื่อเก็บชิ้นส่วนกุญแจ"
	)
	pickup.position = Vector2(200, 200)
	root.add_child(pickup)
	var initial_y: float = pickup.get_node("Visual").position.y
	await create_timer(0.18).timeout
	if is_equal_approx(pickup.get_node("Visual").position.y, initial_y):
		_fail("Key fragment visual does not bob vertically")
		return

	var player := CharacterBody2D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 0
	var player_collision := CollisionShape2D.new()
	var player_shape := CircleShape2D.new()
	player_shape.radius = 9.0
	player_collision.shape = player_shape
	player.add_child(player_collision)
	player.position = pickup.position
	root.add_child(player)
	for _frame: int in range(3):
		await physics_frame
	if not pickup.get_node("Prompt").visible:
		_fail("Key fragment prompt did not appear for the nearby player")
		return

	var collection_state := {"count": 0, "item_id": ""}
	pickup.connect("collection_requested", func(collected_pickup: Area2D) -> void:
		collection_state["count"] += 1
		collection_state["item_id"] = String(collected_pickup.get("item_id"))
	)
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.pressed = true
	pickup.call("_input", key_event)
	pickup.call("_input", key_event)
	if int(collection_state["count"]) != 1:
		_fail("Key fragment emitted more than one collection request")
		return
	if String(collection_state["item_id"]) != "lanka_key_fragment_shaft":
		_fail("Key fragment emitted the wrong inventory item ID")
		return

	print("Key fragment pickup runtime passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
