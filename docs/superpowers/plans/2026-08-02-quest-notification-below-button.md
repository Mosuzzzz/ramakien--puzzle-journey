# Quest Notification Below Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Place the unread arrow below the shared quest button and animate only the unread quest button with a slow dim-and-scale pulse.

**Architecture:** Keep all behavior in the existing shared `quest_log` scene and script so every chapter receives the fix. Derive the arrow base position from the button bounds, retain an independent arrow bob tween, and manage a second tween whose lifetime follows unread state.

**Tech Stack:** Godot 4.7, GDScript, SceneTree headless runtime tests

## Global Constraints

- The arrow is centered below the quest button with a 6-pixel gap.
- The arrow only moves vertically; it never dims or scales.
- The quest button pulses only while a quest is unread.
- The pulse cycles from normal color and scale to moderately dim and `Vector2(1.10, 1.10)`, then back, over approximately 1.8 seconds.
- Acknowledging the quest immediately restores `Color.WHITE` and `Vector2.ONE`.
- The behavior is shared by Chapters 1–9 through `scenes/ui/quest_log.gd`.

---

### Task 1: Quest unread placement and attention animation

**Files:**
- Modify: `tests/test_quest_notifications_runtime.gd`
- Modify: `scenes/ui/quest_log.gd`

**Interfaces:**
- Consumes: existing `QuestLog.set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void`, `QuestLog.has_unread_notification() -> bool`, and `QuestButton.pressed`.
- Produces: private `_position_notification_below_button() -> void`, `_start_button_attention() -> void`, and `_stop_button_attention() -> void`; no public API changes.

- [ ] **Step 1: Add failing placement and animation assertions**

Add these assertions after obtaining `button` and `notice`, and around the first unread/acknowledge flow:

```gdscript
_expect(
	notice.position.y >= button.position.y + button.size.y,
	"notification sits below quest button"
)
var notice_default_modulate := notice.modulate
var notice_default_scale := notice.scale
quest.set_quest("เควสแรก", "รายละเอียดแรก")
await create_timer(0.75).timeout
_expect(
	button.scale != Vector2.ONE or button.modulate != Color.WHITE,
	"unread quest animates button attention"
)
_expect(
	notice.modulate == notice_default_modulate and notice.scale == notice_default_scale,
	"notification arrow only bobs"
)
button.pressed.emit()
_expect(button.scale == Vector2.ONE, "acknowledge restores button scale")
_expect(button.modulate == Color.WHITE, "acknowledge restores button color")
```

Keep the existing visibility, bobbing, duplicate-refresh, completion, HUD restore, and clear assertions.

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
sh tests/run_quest_notification_tests.sh
```

Expected: FAIL for `notification sits below quest button` and/or `unread quest animates button attention`, proving that the current fixed-above placement and missing button pulse are detected.

- [ ] **Step 3: Implement derived arrow placement**

In `scenes/ui/quest_log.gd`, add:

```gdscript
const NOTIFICATION_BUTTON_GAP := 6.0

func _position_notification_below_button() -> void:
	_notification.position = Vector2(
		_button.position.x + (_button.size.x - _notification.size.x) * 0.5,
		_button.position.y + _button.size.y + NOTIFICATION_BUTTON_GAP
	)
```

Call `_position_notification_below_button()` in `_ready()` before capturing `_notification_base_y` and creating the arrow bob tween. This makes the existing bob animation use the new below-button base.

- [ ] **Step 4: Implement unread quest-button attention tween**

Add these constants and state:

```gdscript
const BUTTON_DIM_COLOR := Color(0.62, 0.62, 0.62, 1.0)
const BUTTON_PULSE_SCALE := Vector2(1.10, 1.10)
const BUTTON_PULSE_HALF_SECONDS := 0.65
const BUTTON_PULSE_REST_SECONDS := 0.50

var _button_attention_tween: Tween
```

Set `_button.pivot_offset = _button.size * 0.5` in `_ready()`. Add the tween helpers:

```gdscript
func _start_button_attention() -> void:
	_stop_button_attention()
	_button_attention_tween = create_tween().set_loops()
	_button_attention_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_button_attention_tween.tween_property(
		_button, "modulate", BUTTON_DIM_COLOR, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.parallel().tween_property(
		_button, "scale", BUTTON_PULSE_SCALE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.tween_property(
		_button, "modulate", Color.WHITE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.parallel().tween_property(
		_button, "scale", Vector2.ONE, BUTTON_PULSE_HALF_SECONDS
	)
	_button_attention_tween.tween_interval(BUTTON_PULSE_REST_SECONDS)

func _stop_button_attention() -> void:
	if _button_attention_tween != null:
		_button_attention_tween.kill()
		_button_attention_tween = null
	_button.modulate = Color.WHITE
	_button.scale = Vector2.ONE
```

Update `_set_notification_unread(unread: bool)` so `true` calls `_start_button_attention()` only when transitioning from read to unread, while `false` calls `_stop_button_attention()`. Preserve the current visibility expression for the arrow.

- [ ] **Step 5: Run the focused test and verify GREEN**

Run:

```bash
sh tests/run_quest_notification_tests.sh
```

Expected: `PASS: quest notifications runtime`.

- [ ] **Step 6: Run regression and parse checks**

Run:

```bash
for test_runner in tests/run_*_tests.sh; do sh "$test_runner" || exit 1; done
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
git diff --check
```

Expected: all test runners print `PASS`, Godot exits with code 0, and `git diff --check` prints no errors. Existing macOS CA, resource-leak, imported-resource UID, or sandboxed editor-settings warnings may remain non-fatal.

- [ ] **Step 7: Commit the implementation**

```bash
git add tests/test_quest_notifications_runtime.gd scenes/ui/quest_log.gd
git commit -m "fix: move quest alert below button"
```
