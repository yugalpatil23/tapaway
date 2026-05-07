# 🎯 Tap Away - Arrow Puzzle Game (Flutter)

A 2D arrow puzzle game inspired by **Arrow Puzzle: Tap Away** — built in Flutter with endless procedurally-generated levels.

---

## 🎮 How to Play

1. You see a **grid** filled with colored arrow blocks
2. **Tap** a block to make it slide in the direction its arrow points
3. A block can only slide if the **path to the edge is clear**
4. **Clear all blocks** from the grid to complete the level
5. Earn up to **3 stars** based on your move count

---

## 📁 Project Structure

```
tap_away/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── models/
│   │   ├── arrow_block.dart             # ArrowBlock model + ArrowDirection enum
│   │   └── game_state.dart              # GameState (ChangeNotifier) + LevelGenerator
│   ├── screens/
│   │   ├── home_screen.dart             # Home screen + level selector (50 levels)
│   │   └── game_screen.dart             # Main game play screen
│   └── widgets/
│       ├── arrow_block_widget.dart      # Individual block with slide animation
│       ├── game_grid.dart               # Grid renderer (Stack + Positioned)
│       └── level_complete_overlay.dart  # Animated completion dialog
└── pubspec.yaml
```

---

## 🚀 Setup & Run

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin

### Steps

```bash
# 1. Copy the tap_away folder to your workspace

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run

# 4. Build APK
flutter build apk --release
```

---

## ✨ Features

| Feature                | Details                                                        |
| ---------------------- | -------------------------------------------------------------- |
| **Endless Levels**     | Procedurally generated — infinite levels, never repeats        |
| **Smart Generation**   | Direction bias toward nearest edge ensures solvability         |
| **Growing Difficulty** | Grid grows from 4×4 (Level 1) up to 10×10 (Level 21+)          |
| **Slide Animation**    | Smooth slide-out + fade animation on each block                |
| **Star Rating**        | 3 stars = optimal moves, 2 stars = slightly over, 1 star = any |
| **Hint System**        | Live count of how many arrows can currently move               |
| **Level Selector**     | 50 levels accessible from home screen                          |
| **Color Coded**        | Each direction group has a distinct color                      |

---

## 🧠 Game Logic

### Solvability

The level generator creates puzzles using a **directional bias algorithm**:

- Each block's direction is weighted toward the **nearest grid edge**
- Higher levels introduce **more random directions** to increase difficulty
- This ensures a solve path always exists (at least edge-adjacent blocks can always escape)

### Can-Slide Check

```dart
bool canSlide(ArrowBlock block) {
  // Walk from block in its arrow direction
  // If ANY non-removed block is in the path → blocked
  // If the walk exits the grid boundary → free to slide!
}
```

### Difficulty Scaling

| Level Range | Grid Size | Density | Difficulty |
| ----------- | --------- | ------- | ---------- |
| 1–5         | 4×4       | 30%     | Easy       |
| 6–15        | 5×6       | 40–50%  | Medium     |
| 16–30       | 7×8       | 55–65%  | Hard       |
| 31+         | 9×10      | 65–75%  | Expert     |

---

## 🛠️ Extending the Game

### Add Sound Effects

```yaml
# pubspec.yaml
dependencies:
  audioplayers: ^6.0.0
```

Play sounds in `GameState.tapBlock()` on slide and level complete.

### Add Persistent Progress

```yaml
dependencies:
  shared_preferences: ^2.2.2
```

Save completed levels and stars in `HomeScreen`.

### Add Haptics

```dart
// In ArrowBlockWidget onTap:
HapticFeedback.lightImpact(); // on tap
HapticFeedback.mediumImpact(); // on level complete
```

### Add Timed Levels

Track elapsed time per level with a `Stopwatch` in `GameState`.

### Add Locked Levels (progression)

Store unlocked levels in SharedPreferences and only allow tapping unlocked `_LevelCell` items.

---

## 🎨 Colour Palette

| Color  | Hex       | Direction |
| ------ | --------- | --------- |
| Blue   | `#2196F3` | → Right   |
| Pink   | `#E91E63` | ↓ Down    |
| Green  | `#4CAF50` | ↑ Up      |
| Orange | `#FF9800` | ← Left    |
| Purple | `#9C27B0` | Mixed     |
| Cyan   | `#00BCD4` | Mixed     |

---

## 📱 Screenshots

The game features:

- **Dark navy home screen** with level grid
- **Light puzzle screen** with colored arrow blocks on a white grid
- **Animated completion overlay** with bouncing stars

---

Built with ❤️ in Flutter
