# Chapter 2 Image Matching Puzzle Design

## Goal

Improve the Chapter 2 ashram-supplies matching puzzle so that the left column uses the four supplied illustrations instead of item names. Correct matches communicate their relationship through a shared, pair-specific border color. Incorrect matches flash red and then become available for another attempt.

## Scope

This change covers only the shared matching-puzzle component and its Chapter 2 configuration. The Chapter 2 quest progression, completion signal, audio feedback, and right-column wording remain unchanged.

The four left-side illustrations represent, in order:

1. Firewood (`ฟืน`)
2. Stream water (`น้ำจากลำธาร`)
3. Herbs (`สมุนไพร`)
4. Dry leaves (`ใบไม้แห้ง`)

The left cards display only the illustrations. They do not display item-name captions.

## Data Model and Assets

Copy the four supplied PNG files into `assets/puzzles/chapter_2/` with descriptive ASCII filenames. Chapter 2 passes each pair to the shared matching puzzle as structured data containing the illustration resource path and the existing right-side description.

The matching component continues to accept its current text-only pair representation for backward compatibility. It additionally accepts image-backed left items, so image rendering is explicit rather than inferred from filename or content.

## Layout and Interaction

Each left item is an image button with a consistent card size. The illustration preserves its aspect ratio and is cropped or contained within the available card area without stretching. The right column remains text buttons, and its order remains shuffled each time the puzzle opens.

Selecting an unmatched left card gives it a thin gold border. Selecting another unmatched left card moves that selection border to the newly selected card.

When a right card is selected:

- If the pair is correct, both cards become disabled and receive the same persistent border color. The four pair colors are orange, yellow, blue, and green, assigned by the pair's stable source index. Text color is not changed to green.
- If the pair is incorrect, both cards become temporarily unavailable and their borders flash red three times. After the feedback animation, both borders return to their prior neutral state and the cards become selectable again.

Existing correct-answer and wrong-answer sound effects continue to play. After all four pairs are correct, the puzzle waits briefly, closes, unpauses the scene, and emits its existing `solved` signal.

## Component Boundaries

`chapter_2.gd` owns the semantic pair definitions and image paths. `matching_puzzle.gd` owns card construction, selection, matching, border-state rendering, temporary input locking, and completion. `matching_puzzle.tscn` owns the static modal layout and visual spacing.

Border styles are created through small focused helpers so that neutral, selected, correct, and incorrect states can be applied consistently to both image and text buttons.

## Error and Edge-Case Handling

The puzzle ignores right-card input when no left card is selected. Disabled correct pairs cannot be selected again. Input on the two cards involved in incorrect feedback is ignored until the flash sequence ends, preventing overlapping attempts from corrupting state.

If an image resource cannot be loaded, the left card remains present with a safe placeholder appearance rather than breaking puzzle construction. The supplied asset paths will also be covered by an automated assertion so missing project assets are detected during testing.

## Testing

Use test-driven development for each behavior:

1. Verify Chapter 2 supplies four valid image-backed pair definitions in the intended semantic order.
2. Verify image-backed left entries create image-only cards while legacy text pairs still create text cards.
3. Verify a correct match gives both cards the same persistent border color and different pairs receive different colors.
4. Verify an incorrect match enters red-border feedback and returns both cards to a selectable neutral state after the animation.
5. Verify correct and incorrect audio hooks still fire and puzzle completion behavior remains intact.

Run the focused matching-puzzle tests first, then the existing puzzle-audio suite and relevant Chapter 2 quest-flow tests. Finally launch or render the Chapter 2 puzzle at the project's supported viewport to visually confirm image cropping, spacing, border visibility, and Thai text layout.

## Acceptance Criteria

- Chapter 2 shows the supplied firewood, stream-water, herb, and dry-leaf illustrations in the left column with no item-name captions.
- Every correct pair is locked with a matching border on both cards, using a different color for each of the four pairs.
- Incorrect pairs flash red three times and can be attempted again afterward.
- Text is not recolored green to indicate success.
- All four correct matches complete the existing quest flow without regression.
- The shared matching component remains compatible with text-only pair data.
