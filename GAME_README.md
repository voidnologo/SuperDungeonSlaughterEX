# Super Dungeon Slaughter EX

A retro-styled dungeon crawler web game built with Elixir Phoenix LiveView.

## Overview

This is a port of the Python CLI game "Super Dungeon Slaughter" to a modern web application using Phoenix LiveView. The game features real-time reactive UI, turn-based combat, character progression, and comprehensive statistics tracking.

## Features

- **Real-time Gameplay**: LiveView provides instant feedback without page reloads
- **Turn-based Combat**: Fight or rest to survive against increasingly powerful monsters
- **Character Progression**: Level up system with stat scaling
- **11 Monster Types**: From weak Kobolds to fearsome Greater Dragons
- **Statistics Tracking**:
  - Total damage dealt
  - Total health healed
  - Kill count per monster type
- **Game Over Screen**: Comprehensive statistics display on death
- **High Score System**: Persistent leaderboard stored in JSON
- **Retro Aesthetic**: Green terminal-style text with color-coded health indicators

## How to Play

1. **Start the Game**:
   ```bash
   mix phx.server
   ```
   Visit `http://localhost:4000` in your browser.

2. **Enter Your Hero's Name**: Choose a name for your character

3. **Combat Actions**:
   - **FIGHT**: Attack the monster (monster will counter-attack if alive)
   - **REST**: Heal yourself (monster will attack you while resting)

4. **Leveling Up**:
   - Kill monsters to gain experience
   - Level up after killing N monsters (where N = your current level)
   - Each level increases your HP, damage, and healing power

5. **Game Over**:
   - When your hero dies, view your final statistics
   - Your score is automatically saved to the leaderboard
   - Click "New Game?" to start a fresh adventure

## Game Mechanics

### Combat

- **Hero Damage**: Random between `damage_min` and `damage_max`
- **Monster Damage**: Gaussian distribution based on `damage_base` ± `damage_sigma`
- **Healing**: Random between `heal_min` and `heal_max` (capped at max HP)

### Leveling

- **Threshold**: Kill N monsters at level N to advance (e.g., 3 kills at level 3)
- **HP Growth**: Max HP increases by your new level
- **Damage Growth**: 10% increase per level (minimum +1)
- **Heal Growth**: 15% increase per level (minimum +1)

### Monsters

Monsters are spawned based on your current level:

- **Early Game** (Level 1-3): Kobold, Slime, Goblin
- **Mid Game** (Level 4-6): Werebat, Rabid Wombat, Orc
- **Late Game** (Level 7-9): Undying, Drake, Kitten
- **End Game** (Level 10+): Lesser Dragon, Greater Dragon

All monsters use Gaussian-distributed stats for realistic variability.

### Health Color Coding

- **Green**: HP > 66%
- **Yellow**: 33% < HP ≤ 66%
- **Red**: HP ≤ 33%

## Project Structure

```
lib/
├── super_dungeon_slaughter_ex/
│   ├── application.ex           # Application supervisor
│   ├── score.ex                 # Score data model
│   ├── game/                    # Core game logic
│   │   ├── hero.ex              # Hero entity with stats & progression
│   │   ├── monster.ex           # Monster entity with Gaussian stats
│   │   └── game_state.ex        # Game state management
│   └── repos/                   # Data persistence
│       ├── monster_repo.ex      # Monster template repository (GenServer)
│       └── score_repo.ex        # High score repository (GenServer)
├── super_dungeon_slaughter_ex_web/
│   ├── components/
│   │   ├── core_components.ex   # Phoenix core UI components
│   │   └── game_components.ex   # Game-specific UI components
│   └── live/
│       └── game_live.ex         # Main game LiveView

priv/
└── data/
    ├── monsters.json            # Monster templates
    └── scores.json              # Persistent high scores
```

## Technical Details

### Architecture

- **LiveView**: Stateful WebSocket-based UI with server-side rendering
- **GenServers**: MonsterRepo and ScoreRepo manage shared game data
- **Supervision Tree**: Repos started at application boot for reliability
- **Functional Core**: Pure functions in Hero, Monster, and GameState modules

### State Management

- **Game State**: Stored in LiveView process (per browser session)
- **Repositories**: GenServers provide thread-safe access to shared data
- **Persistence**: Scores automatically saved to JSON on game over

### Statistics Tracking

The hero tracks:
- `total_damage_dealt`: Sum of all damage inflicted
- `total_health_healed`: Sum of all HP restored via resting
- `monsters_killed_by_type`: Map of monster names to kill counts

### Styling

- **Tailwind CSS**: Utility-first styling
- **Color Scheme**: Dark gray/black background with green terminal text
- **Retro Theme**: Monospace font, thick borders, bright accent colors
- **Responsive**: Adapts to desktop, tablet, and mobile screens

## Development

### Prerequisites

- Elixir 1.19+ with OTP 28
- Phoenix 1.8+
- Modern web browser

### Setup

```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Run tests (if implemented)
mix test

# Start the development server
mix phx.server
```

### Configuration

Game data files are located in `priv/data/`:
- `monsters.json`: Define monster stats and level ranges
- `scores.json`: High scores (created automatically)

## Future Enhancements

The architecture supports easy addition of:
- **Inventory System**: Items, weapons, armor
- **Consumables**: Potions, scrolls
- **Spells**: Magic attacks with mana system
- **Multiplayer**: Shared leaderboards, spectate mode
- **Achievements**: Track milestones and feats

## Credits

**Original Python Game**: Super Dungeon Slaughter
**Phoenix Port**: Super Dungeon Slaughter EX
**Framework**: Phoenix LiveView
**Language**: Elixir

---

Enjoy slaying monsters! 🐉⚔️
