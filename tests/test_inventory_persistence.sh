#!/bin/sh
set -eu

inventory="scenes/ui/inventory.gd"

grep -Fq '"jatayu_feather"' "$inventory"
grep -Fq '"ขนนกพญาชฎายุ"' "$inventory"
grep -Fq 'res://assets/ui/icon/split/icon_wing.png' "$inventory"
grep -Fq 'func get_items_snapshot() -> Dictionary:' "$inventory"
grep -Fq 'func restore_items(snapshot: Dictionary) -> void:' "$inventory"
grep -Fq 'func reset_for_new_story() -> void:' "$inventory"
grep -Fq 'items = {"potion": 3}' "$inventory"

echo "Inventory persistence contract passed"
