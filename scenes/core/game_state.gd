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

# whether the Chapter 6 Lanka gate intro cutscene has already played this run
static var chapter_6_intro_played := false
static var chapter_6_yak_defeated := false
static var chapter_6_yak_fragment_position := Vector2.INF
static var chapter_6_left_chest_unlocked := false
static var chapter_6_right_jars_mask := 0
static var chapter_6_right_pedestal_solved := false
static var chapter_6_gate_unlocked := false

# whether Thotsakan has been defeated in Chapter 9
static var chapter_9_thotsakan_defeated := false

# whether Sida has been rescued from the locked Chapter 8 room
static var chapter_9_sida_rescued := false

# whether the Chapter 8 palace intro cutscene has already played this run
static var chapter_8_intro_played := false
