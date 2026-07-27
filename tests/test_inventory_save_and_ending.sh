#!/bin/sh
set -eu

save_game="scenes/core/save_game.gd"
ending="scenes/ending/ending.gd"

grep -Fq '"inventory": inventory.get_items_snapshot()' "$save_game"
grep -Fq 'if data.has("inventory"):' "$save_game"
grep -Fq 'inventory.restore_items(data["inventory"])' "$save_game"
grep -Fq 'Inv.reset_for_new_story()' "$ending"

echo "Inventory save and Ending reset contract passed"
