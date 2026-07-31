extends CharacterBody2D

const MobScene := preload("res://scenes/props/mob.tscn")
const WaveScene := preload("res://scenes/props/wave.tscn")

@export var max_health: int = 220
@export var contact_damage: int = 25
@export var attack_range: float = 90.0
@export var attack_cooldown: float = 2.8
@export var display_height: float = 130.0
# accumulated damage taken before he staggers into the stun pose
@export var stun_threshold: float = 60.0
# stop summoning while this many of his minions are still alive
@export var max_minions: int = 4
# hits landed while he's not stunned only chip this fraction of their damage through;
# the real damage happens through the stun-quiz hits instead
@export_range(0.0, 1.0) var normal_damage_scale: float = 0.15

# ground-slam impact lands here in the trimmed 12-frame attack clip
const ATTACK_HIT_FRAME := 5
# spawn minions on the last frame of the 6-frame summon clip (s0,s4,s5,s6,s7,s8)
const SUMMON_SPAWN_FRAME := 5
# the attack/summon/stun sheets have more transparent padding around the body than idle,
# so they need extra scale to make the character read the same size on-screen
const ANIM_DISPLAY_SCALE := {"attack": 1.1, "summon": 1.03, "stun": 0.97}

# fractions of the boss hp_bar texture width where the red pill begins/ends
# (the same shared boss bar art used by other bosses)
const BOSS_FILL_START := 0.171
const BOSS_FILL_END := 0.825

# while stunned, each hit poses a question instead of landing directly;
# a correct answer lands the bonus hit, a wrong one lets him off free
const QUESTIONS := [
	["คำว่า “เดิน” เป็นคำชนิดใด?", ["คำนาม", "คำกริยา", "คำวิเศษณ์"], 1],
	["คำใดสะกดถูกต้อง?", ["อนุญาติ", "อนุญาต", "อนุญาส"], 1],
	["คำใดอยู่ในมาตราตัวสะกดแม่กน?", ["จันทร์", "เมฆ", "นก"], 0],
	["คำว่า “สวยงาม” เป็นคำประเภทใด?", ["คำซ้อน", "คำซ้ำ", "คำสมาส"], 0],
	["ข้อใดเป็นคำราชาศัพท์ของคำว่า “กิน”?", ["เสวย", "ฉัน", "รับประทาน"], 0],
	["คำใดเป็นคำพ้องเสียงกับ “กาล”?", ["การ", "กาฬ", "ถูกทั้งสองข้อ"], 2],
	["“อิเหนา” เป็นวรรณคดีประเภทใด?", ["นิทาน", "บทละคร", "นิราศ"], 1],
	["คำว่า “มานะ” หมายความว่าอย่างไร?", ["ความเกียจคร้าน", "ความเพียรพยายาม", "ความโกรธ"], 1],
	["คำใดเป็นคำซ้อน?", ["บ้านเรือน", "เด็กเด็ก", "สวยงามตระการตา"], 0],
	["คำใดอยู่ในมาตราตัวสะกดแม่กง?", ["ลิง", "ดาว", "เมฆ"], 0],
	["ข้อใดเป็นคำพ้องรูป?", ["เพลา (เวลา/ล้อรถ)", "ม้า/หมา", "กา/ปลา"], 0],
	["คำใดสะกดผิด?", ["อนุญาต", "ผัดวันประกันพรุ่ง", "โอกาศ"], 2],
	["คำว่า “สุนทรพจน์” อ่านว่าอย่างไร?", ["สุน-ทอน-ระ-พด", "สุน-ทะ-ระ-พด", "สุน-ทอน-พด"], 1],
]

var _health: int = max_health
var _hit_cooldown: float = 0.0
var _player: Node2D
var _attacking := false
var _stunned := false
var _stagger_damage: float = 0.0
var _minions: Array = []
var _hit_flash_tween: Tween
var _dodge_tween: Tween
var _quiz_open := false
var _pending_damage := 0
var _question_queue: Array = []
# indices already answered correctly — never asked again this fight
var _solved_questions: Array = []
var _pending_question_index := -1

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _boss_bar: TextureProgressBar = $BossHUD/BossBar
@onready var _quiz: CanvasLayer = $QuestionQuiz


func _ready() -> void:
	_health = max_health
	_player = get_parent().get_node_or_null("Player")
	_play("idle")
	_update_boss_bar()
	_quiz.answered.connect(_on_quiz_answered)
	_question_queue = range(QUESTIONS.size())
	_question_queue.shuffle()

func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _attacking:
		return
	if _stagger_damage >= stun_threshold:
		_start_stun()
		return
	if _player == null or _hit_cooldown > 0.0:
		return
	if not _is_on_screen():
		return
	# as soon as he's in frame: randomly waves or summon, every cooldown
	if randi() % 2 == 0 and _alive_minion_count() < max_minions:
		_start_summon()
	else:
		_start_attack()

func _alive_minion_count() -> int:
	_minions = _minions.filter(func(m): return is_instance_valid(m))
	return _minions.size()

func _is_on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return true
	var screen_size: Vector2 = get_viewport_rect().size / cam.zoom
	var cam_pos: Vector2 = cam.get_screen_center_position()
	var visible_rect := Rect2(cam_pos - screen_size / 2.0, screen_size)
	return visible_rect.has_point(global_position)

func _start_stun() -> void:
	_attacking = true
	_stunned = true
	_stagger_damage = 0.0
	# stun clip ends collapsed asleep, so: collapse (1.6s) -> hold (0.5s) ->
	# play back in reverse to get up (1.6s) = ~3.7s total
	_play("stun")
	await _sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	_sprite.play(&"stun", -1.0)
	await _sprite.animation_finished
	_stunned = false
	_attacking = false
	_play("idle")

func _start_summon() -> void:
	_attacking = true
	_hit_cooldown = attack_cooldown
	_play("summon")
	while _sprite.animation == &"summon" and _sprite.frame < SUMMON_SPAWN_FRAME:
		await _sprite.frame_changed
	_spawn_minion(Vector2(-95, 10))
	_spawn_minion(Vector2(95, 10))
	await _sprite.animation_finished
	_attacking = false
	_play("idle")

func _spawn_minion(offset: Vector2) -> void:
	var minion := MobScene.instantiate()
	get_parent().add_child(minion)
	minion.global_position = global_position + offset
	_minions.append(minion)

func _spawn_wave(dir: Vector2) -> void:
	var wave := WaveScene.instantiate()
	wave.direction = dir
	wave.shooter = self
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(0, 10)

func _start_attack() -> void:
	_attacking = true
	_hit_cooldown = attack_cooldown
	_play("attack")
	while _sprite.animation == &"attack" and _sprite.frame < ATTACK_HIT_FRAME:
		await _sprite.frame_changed
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		if (_player.global_position - global_position).length() <= attack_range + 20.0:
			_player.take_damage(contact_damage)
	_spawn_wave(Vector2.LEFT)
	_spawn_wave(Vector2.RIGHT)
	await _sprite.animation_finished
	_attacking = false
	_play("idle")

func take_damage(amount: int) -> void:
	if _quiz_open:
		return
	if not _stunned:
		_flash_hit()
		_health -= roundi(amount * normal_damage_scale)
		_stagger_damage += amount
		_update_boss_bar()
		if _health <= 0:
			await get_tree().create_timer(0.12).timeout
			queue_free()
		return
	# stunned: this hit only lands if a quiz question is answered correctly
	if _question_queue.is_empty():
		_question_queue = range(QUESTIONS.size()).filter(
			func(i): return not _solved_questions.has(i)
		)
		_question_queue.shuffle()
	if _question_queue.is_empty():
		# every question has already been answered correctly this fight —
		# nothing left to quiz him on, so the hit just lands
		_flash_hit()
		_health -= amount
		_update_boss_bar()
		if _health <= 0:
			await get_tree().create_timer(0.12).timeout
			queue_free()
		return
	_dodge_hit()
	_pending_damage = amount
	_quiz_open = true
	_pending_question_index = _question_queue.pop_front()
	var q: Array = QUESTIONS[_pending_question_index]
	_quiz.call("ask", q[0], q[1], q[2])

func _on_quiz_answered(correct: bool) -> void:
	_quiz_open = false
	if not correct:
		_pending_damage = 0
		return
	if not _solved_questions.has(_pending_question_index):
		_solved_questions.append(_pending_question_index)
	_flash_hit()
	_health -= _pending_damage
	_pending_damage = 0
	_update_boss_bar()
	if _health <= 0:
		await get_tree().create_timer(0.12).timeout
		queue_free()

func _update_boss_bar() -> void:
	var frac := float(_health) / float(maxi(max_health, 1))
	_boss_bar.value = _boss_bar.max_value * lerpf(BOSS_FILL_START, BOSS_FILL_END, frac)

func _dodge_hit() -> void:
	if is_instance_valid(_dodge_tween):
		_dodge_tween.kill()
	var start_pos := _sprite.position
	_dodge_tween = create_tween()
	_dodge_tween.tween_property(_sprite, "position", start_pos + Vector2(24, 0), 0.08)
	_dodge_tween.tween_property(_sprite, "position", start_pos, 0.1)

func _flash_hit() -> void:
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	_sprite.modulate = Color(1, 0.15, 0.15)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_interval(0.08)
	_hit_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, 0.18)

func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.animation = anim
	# scale from THIS animation's own frame height — the sheets have
	# different resolutions (stun tiles are 107px vs idle's 298px);
	# set unconditionally so autoplay/editor state can't leave a stale scale
	var tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
	var s: float = display_height * float(ANIM_DISPLAY_SCALE.get(anim, 1.0)) / tex.get_height()
	_sprite.scale = Vector2(s, s)
	_sprite.play(anim)
