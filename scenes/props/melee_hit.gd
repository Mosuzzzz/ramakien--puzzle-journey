extends Area2D

@export var damage: int = 20
@export var lifetime: float = 0.2

var shooter: Node2D = null
var _hit_targets: Array = []

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())

func _try_hit(target: Node) -> void:
	if target == shooter or target in _hit_targets:
		return
	if target.has_method("take_damage"):
		_hit_targets.append(target)
		target.take_damage(damage)
