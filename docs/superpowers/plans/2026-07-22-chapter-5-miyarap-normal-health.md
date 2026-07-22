# Chapter 5 Maiyarap Normal Health Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the temporary one-hit health override from Maiyarap in Chapter 5.

**Architecture:** Chapter 5 will stop overriding the boss instance health and inherit the shared `220` default from `miyarap.gd`. No combat or cutscene scripts change.

**Tech Stack:** Godot 4.7 `.tscn`, GDScript configuration, shell structural regression test

## Global Constraints

- Keep the shared default at exactly `220`.
- Do not modify combat behavior, cutscenes, portals, or player switching.
- Preserve unrelated user changes in Chapter 5.

---

### Task 1: Restore inherited boss health

**Files:**
- Modify: `tests/test_chapter_5_post_boss_cutscene.sh`
- Modify: `scenes/chapter_5/chapter_5.tscn`
- Read: `scenes/props/miyarap.gd`

**Interfaces:**
- Consumes: `@export var max_health: int = 220` from `miyarap.gd`.
- Produces: a Chapter 5 Maiyarap instance with no `max_health` override.

- [ ] **Step 1: Add the failing assertions**

```sh
if sed -n '/\[node name="Miyarap"/,/^$/p' "$scene" | grep -Fq 'max_health'; then
	echo "Chapter 5 still overrides Maiyarap health" >&2
	exit 1
fi
grep -Fq '@export var max_health: int = 220' scenes/props/miyarap.gd
```

- [ ] **Step 2: Run the test and confirm the override assertion fails**

Run: `sh tests/test_chapter_5_post_boss_cutscene.sh`

Expected: exit code `1` with `Chapter 5 still overrides Maiyarap health`.

- [ ] **Step 3: Remove only the temporary override**

Remove this property from `YSortRoot/Miyarap` in `chapter_5.tscn`:

```tscn
max_health = 1
```

- [ ] **Step 4: Run verification**

Run: `sh tests/test_chapter_5_post_boss_cutscene.sh`

Expected: `Chapter 5 post-boss cutscene contract passed`.

Run: `sh tests/test_chapter_4_hanuman_after_cutscene.sh`

Expected: `Chapter 4 Hanuman switch contract passed`.

Run: `git diff --check`

Expected: exit code `0` with no output.
