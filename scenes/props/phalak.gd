extends CharacterBody2D

# scale factor: character renders at display_height * (char_px / region_px)
@export var display_height: float = 59.4

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_play("idle")

func _play(anim: String) -> void:
	_update_run_audio(anim == "walk")
	if _sprite.animation != anim:
		_sprite.animation = anim
		var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
		var s := display_height / tex.get_height()
		_sprite.scale = Vector2(s, s)
	_sprite.play(anim)


func _update_run_audio(active: bool) -> void:
	AudioManager.set_run_active(self, active)


func _exit_tree() -> void:
	AudioManager.set_run_active(self, false)
