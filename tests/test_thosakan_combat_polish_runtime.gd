extends SceneTree

var _failures: Array[String] = []


class DamageReceiver:
	extends Node2D
	var current_health := 100
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount
		current_health -= amount


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/props/thosakan.tscn") as PackedScene
	_expect(packed != null, "Thosakan scene loads")
	if packed == null:
		_finish()
		return

	var stage := Node2D.new()
	root.add_child(stage)
	var player := DamageReceiver.new()
	player.name = "Player"
	player.position = Vector2(100.0, 0.0)
	stage.add_child(player)
	var boss := packed.instantiate()
	stage.add_child(boss)
	boss.set_physics_process(false)
	await process_frame

	_expect(is_equal_approx(boss.speed, 75.0), "Thosakan walks at 75 px/s")
	_expect(is_equal_approx(boss.attack_range, 130.0), "Thosakan attack range matches his collision geometry")

	var bar := boss.get_node("BossHUD/BossBar") as TextureProgressBar
	var name_label := boss.get_node_or_null("BossHUD/BossBar/BossName") as Label
	_expect(name_label != null, "BossName follows BossBar layout")
	if name_label != null:
		_expect(name_label.get_theme_font_size("font_size") >= 24, "BossName is at least 24 px")
		_expect(name_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "BossName is horizontally centered")
		_expect(name_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "BossName is vertically centered")
		var bar_center := bar.get_global_rect().get_center()
		var label_center := name_label.get_global_rect().get_center()
		_expect(absf(label_center.x - bar_center.x) <= 1.0, "BossName follows the bar center")

	var sprite := boss.get_node("Sprite") as AnimatedSprite2D
	_expect(not sprite.sprite_frames.has_animation(&"Stunned"), "Stunned animation is excluded")
	_expect(not sprite.sprite_frames.has_animation(&"dead"), "dead animation is excluded")
	boss._physics_process(0.016)
	_expect(boss._attacking, "Thosakan starts a normal attack from 100 px")
	_expect(sprite.animation == &"Attack", "Thosakan plays the existing Attack animation")

	stage.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: Thosakan combat polish runtime")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
