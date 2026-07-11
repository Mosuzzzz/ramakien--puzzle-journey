extends Area2D

@export var speed: float = 420.0
@export var damage: int = 15

var direction := Vector2.RIGHT
var shooter: Node2D = null
var _spent := false

func _ready() -> void:
	# arrow sprite points right; mirror when flying left
	if direction.x < 0:
		$Sprite.flip_h = true
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())

func _try_hit(target: Node) -> void:
	if _spent or target == shooter:
		return
	if target.has_method("take_damage"):
		_spent = true
		target.take_damage(damage)
		queue_free()
