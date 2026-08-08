# Remove Quest Arrow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the floating quest arrow/flame while preserving unread quest state and the quest-button pulse animation.

**Architecture:** Delete the visual node and texture dependency from the reusable quest HUD scene, then remove only the script state and tween code that controls that visual. Keep `_notification_unread` as the source of truth and keep `_start_button_attention()`/`_stop_button_attention()` unchanged.

**Tech Stack:** Godot 4.7, GDScript, headless Godot runtime tests, shell test runners

## Global Constraints

- Remove only the `QuestNotification` visual and its vertical bob animation.
- Preserve logical unread state, quest-button dim/bright pulse, periodic scale animation, and acknowledgement behavior.
- Do not delete `assets/ui/icon/split/icon_flame.png`, because it may be used by other game systems.
- All focused and full-project tests must pass.

---

### Task 1: Remove the quest arrow without changing unread behavior

**Files:**
- Modify: `tests/test_quest_notifications_runtime.gd:10-57`
- Modify: `scenes/ui/quest_log.tscn:11,70-78`
- Modify: `scenes/ui/quest_log.gd:6-8,18-19,31,39-51,127-143,183-189`

**Interfaces:**
- Consumes: `QuestLog.set_quest(quest_name: String, detail: String = "", target: Vector2 = Vector2.INF) -> void`, `QuestLog.set_hud_visible(shown: bool) -> void`, and `QuestLog.has_unread_notification() -> bool`.
- Produces: a `QuestLog` scene with no `QuestNotification` child; unread quests still animate `QuestButton`, and pressing `QuestButton` still acknowledges them.

- [ ] **Step 1: Rewrite the runtime test to require that the arrow is absent**

Replace the arrow-specific setup and assertions in `_run()` with this behavior-focused sequence:

```gdscript
	var button := quest.get_node("QuestButton") as TextureButton
	_expect(
		quest.get_node_or_null("QuestNotification") == null,
		"quest notification arrow is removed"
	)
	quest.set_quest("เควสแรก", "รายละเอียดแรก")
	_expect(quest.has_unread_notification(), "new quest notifies")
	await create_timer(0.55).timeout
	_expect(
		button.scale != Vector2.ONE or button.modulate != Color.WHITE,
		"unread quest animates button attention"
	)
	button.pressed.emit()
	_expect(not quest.has_unread_notification(), "press acknowledges")
	_expect(button.scale == Vector2.ONE, "acknowledge restores button scale")
	_expect(button.modulate == Color.WHITE, "acknowledge restores button color")
	quest.set_quest("เควสแรก", "รายละเอียดแรก")
	_expect(not quest.has_unread_notification(), "identical refresh stays read")
	quest.set_quest("เควสแรก", "รายละเอียดใหม่")
	_expect(quest.has_unread_notification(), "detail change notifies")
	button.pressed.emit()
	quest.set_completed(true)
	_expect(quest.has_unread_notification(), "completion change notifies")
	button.pressed.emit()
	quest.set_completed(true)
	_expect(not quest.has_unread_notification(), "same completion stays read")
	quest.set_quest("เควสซ่อน HUD", "ยังไม่ได้อ่าน")
	quest.set_hud_visible(false)
	_expect(quest.has_unread_notification(), "hidden HUD preserves unread")
	quest.set_hud_visible(true)
	_expect(quest.has_unread_notification(), "restored HUD preserves unread")
	quest.clear()
	_expect(not quest.has_unread_notification(), "clear removes unread")
```

- [ ] **Step 2: Run the focused test and verify that it fails for the intended reason**

Run:

```bash
sh tests/run_quest_notification_tests.sh
```

Expected: FAIL with `quest notification arrow is removed`, because the scene still contains `QuestNotification`. Existing unread-button assertions should not fail.

- [ ] **Step 3: Remove the arrow resource and node from the scene**

Delete this resource declaration from `scenes/ui/quest_log.tscn`:

```gdscript
[ext_resource type="Texture2D" path="res://assets/ui/icon/split/icon_flame.png" id="11_quest_notification"]
```

Delete this node block from the same scene:

```gdscript
[node name="QuestNotification" type="TextureRect" parent="."]
offset_left = 25.0
offset_top = 166.0
offset_right = 59.0
offset_bottom = 200.0
mouse_filter = 2
texture = ExtResource("11_quest_notification")
expand_mode = 1
stretch_mode = 5
```

- [ ] **Step 4: Remove only the arrow animation code from the script**

Delete the three `NOTIFICATION_*` constants, `_notification_base_y`, `_notification_tween`, and the `_notification` on-ready reference. In `_ready()`, delete `_notification.hide()` and the complete positioning/bobbing tween setup. Delete `_position_notification_below_button()`.

Reduce `_set_notification_unread()` to this implementation so the logical unread state and button pulse remain intact:

```gdscript
func _set_notification_unread(unread: bool) -> void:
	var was_unread := _notification_unread
	_notification_unread = unread
	if unread:
		if not was_unread:
			_start_button_attention()
	else:
		_stop_button_attention()
```

Reduce `set_hud_visible()` to this implementation so HUD visibility no longer references the removed node:

```gdscript
func set_hud_visible(shown: bool) -> void:
	_hud_allowed = shown
	_button.visible = shown and _has_quest
	if not shown:
		_page.hide()
```

Do not alter `_start_button_attention()`, `_stop_button_attention()`, `has_unread_notification()`, or `_notification_unread`.

- [ ] **Step 5: Run the focused test and verify that it passes**

Run:

```bash
sh tests/run_quest_notification_tests.sh
```

Expected: exit code 0 and `PASS: quest notifications runtime`.

- [ ] **Step 6: Run the complete project test suite**

Run:

```bash
for test_runner in tests/run_*_tests.sh; do
  sh "$test_runner" || exit 1
done
```

Expected: every test runner exits with code 0, with no GDScript parser or runtime errors.

- [ ] **Step 7: Check the diff and commit the implementation**

Run:

```bash
git diff --check
git diff -- scenes/ui/quest_log.gd scenes/ui/quest_log.tscn tests/test_quest_notifications_runtime.gd
git add scenes/ui/quest_log.gd scenes/ui/quest_log.tscn tests/test_quest_notifications_runtime.gd
git commit -m "fix: remove quest notification arrow"
```

Expected: the diff contains only removal of the arrow visual/bob code and the corresponding test rewrite; the commit succeeds.
