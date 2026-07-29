extends Area2D

@export var item_id := "potion"
@export var bob_height := 4.0
@export var bob_duration := 0.7

var _picked_up := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var bob := create_tween().set_loops()
	bob.tween_property(_sprite, "position:y", _sprite.position.y - bob_height, bob_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_sprite, "position:y", _sprite.position.y, bob_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if _picked_up or not (body is CharacterBody2D and body.name == "Player"):
		return
	_picked_up = true
	Inv.add_item(item_id)
	queue_free()
