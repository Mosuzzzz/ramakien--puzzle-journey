# Software Requirements Specification (SRS)
# Ramakien: Puzzle Journey

## 1. Introduction

### 1.1 Purpose
This document defines the requirements for a 2D educational adventure game based on the Ramakien. The player explores scenes, solves puzzles, collects clues, uses passwords or keys, and progresses through chapters to help Phra Ram rescue Sida and escape from Lanka.

### 1.2 Scope
The game is a 2D title built in Godot for students in grades 2–6. Its main purpose is learning through play, using simple puzzles, observation, matching, and knowledge-based progression to unlock doors or pass stages.

### 1.3 Definitions
- **Player**: The person playing the game.
- **NPC**: Non-player character.
- **Puzzle**: A problem or challenge in the game.
- **Mob**: A small enemy or yak soldier.
- **Boss**: A major enemy in a chapter.
- **Map**: A game area or scene.

### 1.4 References
- Ramakien as the source story.
- Educational escape room design references.
- SRS and GDD template examples.

## 2. Overall Description

### 2.1 Product Perspective
This game is a single-player 2D adventure/puzzle game. The player travels through chapters based on Ramakien story events, with some chapters including light mob combat or boss battles.

### 2.2 Product Functions
- Move through 2D scenes.
- Interact with NPCs and objects.
- Collect clues and items.
- Solve puzzles to receive keys or passwords.
- Fight or avoid mobs.
- Progress through chapters.
- Reach the ending.

### 2.3 User Characteristics
The target users are primary school students in grades 2–6. They should be able to read basic Thai or English instructions and understand simple controls after a short tutorial.

### 2.4 Constraints
- The game must be 2D.
- The engine must be Godot.
- The story must use Ramakien as the main inspiration.
- Difficulty must remain child-friendly.
- Visuals and text must be clear and simple.

### 2.5 Assumptions
- Players can understand simple movement and interaction controls.
- Players can learn the game from short on-screen instructions.
- The game will be played on a standard PC first.

## 3. Game Concept

### 3.1 Story Summary
The game follows Phra Ram and his companions as they journey to rescue Sida, who has been taken to Lanka by Thotsakan. Along the way, players face puzzles, traps, and yak-style enemies inspired by Thai mythology .

### 3.2 Gameplay Loop
1. Receive a mission.
2. Explore the map.
3. Find clues.
4. Solve a puzzle.
5. Receive a key or password.
6. Pass a gate or defeat a mob.
7. Continue to the next chapter.

### 3.3 Chapters and Maps
- Chapter 1: The Royal Palace Introduction.
- Chapter 2: The Forest Path.
- Chapter 3: The Battle Gate.
- Chapter 4: The Miryap Zone.
- Chapter 5: Lanka Infiltration.
- Chapter 6: Sida’s Prison.
- Chapter 7: Final Escape from Lanka.

### 3.4 Characters
- **Phra Ram**: Main hero.
- **Sida**: Rescue target.
- **Phra Lak**: Supporting ally.
- **Hanuman**: Scout and helper.
- **Thotsakan**: Main villain.
- **Yak mobs**: Common enemies.
- **Chapter bosses**: Special enemies at major stages.

## 4. Functional Requirements

### 4.1 Movement
- The player must be able to move left, right, up, and down in 2D.
- The player must be able to jump or interact where needed.

### 4.2 Interaction
- The player must be able to talk to NPCs.
- The player must be able to pick up items.
- The player must be able to open doors, boxes, and other interactable objects.

### 4.3 Puzzle System
- The game must include several puzzle types such as image matching, counting, ordering, and decoding.
- Solving a puzzle must reward the player with a key, password, or open route.
- The game must show feedback when the player answers correctly or incorrectly.

### 4.4 Combat / Mob System
- The game must include simple mobs.
- Mobs must have basic attack behavior.
- Some chapters must include bosses.
- The player must be able to fight or avoid enemies depending on the chapter.
- Combat difficulty must stay appropriate for children.

### 4.5 Hint System
- The game must include a hint system.
- If the player is stuck for too long, a clue should appear.
- Hints should guide the player without revealing everything immediately.

### 4.6 Progression
- The game must support chapter progression.
- Finishing a chapter must unlock the next chapter.
- The game must include checkpoint or save support.

## 5. Non-Functional Requirements

### 5.1 Usability
- The UI must be easy to understand.
- Text must be readable.
- Controls must be simple.

### 5.2 Performance
- The game must run smoothly on a normal PC.
- Scene loading should not be too slow.

### 5.3 Reliability
- The game should not crash frequently.
- Puzzle logic and scene transitions must work correctly.

### 5.4 Maintainability
- The project should use separate Godot scenes for each chapter.
- Code should be organized so the game can be expanded later.

## 6. Design Constraints
- Must use Godot.
- Must be 2D.
- Must be inspired by the Ramakien.
- Must be suitable for children.
- Must avoid overly violent content.

## 7. Chapter Narrative

### 7.1 Chapter 1: The Royal Palace Introduction
The game begins in Phra Ram’s kingdom. The player learns how to move and interact, then receives news that starts the rescue journey.

### 7.2 Chapter 2: The Forest Path
The player travels through a forest with branching paths, hidden clues, and simple puzzles.

### 7.3 Chapter 3: The Battle Gate
The player faces yak guards and solves a puzzle to pass through a locked gate.

### 7.4 Chapter 4: The Miryap Zone
This chapter is inspired by the Miryap battle and includes maze-like navigation, traps, and enemy groups [web:108][web:109][web:117].

### 7.5 Chapter 5: Lanka Infiltration
The player sneaks into Lanka, gathers information, and discovers where Sida is held.

### 7.6 Chapter 6: Sida’s Prison
The player combines clues and solves the final password to rescue Sida.

### 7.7 Chapter 7: Final Escape from Lanka
The player escapes from Lanka while enemy mobs appear in the way.

## 8. User Interface
- Main Menu
- Pause Menu
- Dialogue Box
- Hint Panel
- Inventory
- Health / Progress Display
- Win / Lose Screen

## 9. Audio Requirements
- Background music with Thai fantasy style.
- Movement and interaction sound effects.
- Correct / incorrect answer sounds.
- Combat sounds.
- Victory and completion sounds.

## 10. Acceptance Criteria
The game is considered complete when:
- The player can understand the controls quickly.
- Chapter 1 is fully playable.
- Puzzles work correctly.
- Mob combat works correctly.
- The game ends with a clear conclusion.

## 11. Appendix
- List of maps based on literature.
- Character list.
- Puzzle list.
- Enemy list.
- Asset list.

### Language Support
The game must support two languages: Thai and English (US). Players must be able to switch languages from the settings menu. All menus, dialogue, hints, and notifications must update immediately after the language changes.
