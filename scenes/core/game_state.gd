# where the player should appear after the next scene change; INF = use scene default
static var next_spawn := Vector2.INF

# the active quest to restore after loading a save, applied once when the next
# gameplay scene is ready; empty = nothing to restore
static var next_quest := {}

# whether the chapter 1 plaza intro narration has already played this run
static var chapter_1_intro_played := false

# whether Rama has had his audience with King Thotsarot (heard the exile decree)
static var chapter_1_audience_done := false

# whether the how-to-play tutorial has been shown this run
static var tutorial_shown := false

# whether the chapter 2 forest intro narration has already played this run
static var chapter_2_intro_played := false

# whether the golden deer (Maricha) has already been defeated and Sida abducted
static var chapter_2_deer_defeated := false

# whether the ashram supply matching puzzle has already been solved
static var chapter_2_ashram_puzzle_solved := false

# whether the golden deer's appearance cutscene has already played
static var chapter_2_deer_intro_played := false

# whether the "return to the empty ashram" aftermath quest has been set
static var chapter_2_aftermath_played := false

# whether Thotsakan has been defeated in Chapter 9
static var chapter_9_thotsakan_defeated := false

# whether Sida has been rescued from the locked Chapter 8 room
static var chapter_9_sida_rescued := false

# whether the Chapter 8 palace intro cutscene has already played this run
static var chapter_8_intro_played := false

# whether the Chapter 3 opening (Jatayu) cutscene has already played this run
static var chapter_3_intro_played := false

# whether the Chapter 3 post-battle (Hanuman join) cutscene has already played
static var chapter_3_post_battle_played := false

# whether the Chapter 4 opening cutscene has already played this run
static var chapter_4_intro_played := false

# whether the Chapter 5 post-boss (Miyarap defeat) cutscene has already played
static var chapter_5_post_boss_played := false

# whether the Chapter 6 opening (Lanka gate) cutscene has already played this run
static var chapter_6_intro_played := false


## resets every progress flag for a fresh New Game — the single place to
## touch when adding a new flag, so home_page.gd can't forget one
static func reset_progress() -> void:
	next_spawn = Vector2.INF
	next_quest = {}
	chapter_1_intro_played = false
	chapter_1_audience_done = false
	tutorial_shown = false
	chapter_2_intro_played = false
	chapter_2_deer_defeated = false
	chapter_2_ashram_puzzle_solved = false
	chapter_2_deer_intro_played = false
	chapter_2_aftermath_played = false
	chapter_3_intro_played = false
	chapter_3_post_battle_played = false
	chapter_4_intro_played = false
	chapter_5_post_boss_played = false
	chapter_6_intro_played = false
	chapter_8_intro_played = false
	chapter_9_thotsakan_defeated = false
	chapter_9_sida_rescued = false
