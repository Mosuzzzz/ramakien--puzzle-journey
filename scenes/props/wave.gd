extends Area2D

@export var speed: float = 240.0
@export var damage: int = 18
@export var knockback_force: float = 340.0
# safety net in case it never hits a wall (shouldn't normally trigger)
@export var max_lifetime: float = 6.0

var direction := Vector2.RIGHT
var shooter: Node = null
var _spent := false
# ignore walls for a beat after spawning so it doesn't insta-die if it spawns
# touching/near tight corridor geometry (some chapters have very narrow paths)
var _wall_grace: float = 0.2

@onready var _sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	# wave art crests toward the right; flip so it crests toward the left instead
	_sprite.flip_h = direction.x > 0
	_sprite.play("roll")
	_sprite.animation_finished.connect(queue_free)
	get_tree().create_timer(max_lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	_wall_grace = maxf(_wall_grace - delta, 0.0)
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is StaticBody2D:
		if _wall_grace > 0.0:
			return
		queue_free()
		return
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area.get_parent())

func _try_hit(target: Node) -> void:
	if _spent or target == shooter:
		return
	# boss weapon: rolls over his own minions, only the player gets hit
	if target.name != "Player":
		return
	# dashing phases through: don't damage AND don't spend the wave on it
	var dash_left = target.get("_dash_time_left")
	if dash_left != null and dash_left > 0.0:
		return
	if target.has_method("take_damage"):
		_spent = true
		target.take_damage(damage)
		if target.has_method("apply_knockback"):
			target.apply_knockback(direction, knockback_force)
