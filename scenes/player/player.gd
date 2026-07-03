extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

@export var character_name: String = "Phra Ram"
@export var speed: float = 150.0
@export var max_health: int = 100

var current_health: int = max_health

func _ready() -> void:
	current_health = max_health

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
