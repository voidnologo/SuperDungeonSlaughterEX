# Super Dungeon Slaughter EX 🐉⚔️

A retro-styled dungeon crawler web game built with Elixir Phoenix LiveView. This is a modern port of the Python CLI game "Super Dungeon Slaughter" featuring real-time reactive UI, turn-based combat, character progression, and comprehensive statistics tracking.

## Features

- **Real-time Gameplay** - LiveView provides instant feedback without page reloads
- **Turn-based Combat** - Fight or rest to survive against increasingly powerful monsters
- **Character Progression** - Level up system with stat scaling
- **11 Monster Types** - From weak Kobolds to fearsome Greater Dragons
- **Statistics Tracking** - Total damage dealt, health healed, and kill count per monster type
- **Game Over Screen** - Comprehensive statistics display on death
- **High Score System** - Persistent leaderboard stored in JSON
- **Retro Aesthetic** - Green terminal-style text with color-coded health indicators

## Getting Started

### Prerequisites

- Elixir 1.19+ with OTP 28
- Phoenix 1.8+
- Modern web browser

### Installation

```bash
# Install dependencies
mix deps.get

# Install Node.js dependencies for assets
cd assets && npm install && cd ..
```

### Running the Application

```bash
# Start the Phoenix server
mix phx.server
```

Or start inside IEx (Interactive Elixir):

```bash
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How to Play

1. **Enter Your Hero's Name** - Choose a name for your character
2. **Combat Actions**:
   - **FIGHT** - Attack the monster (monster will counter-attack if alive)
   - **REST** - Heal yourself (monster will attack you while resting)
3. **Leveling Up** - Kill N monsters at level N to advance (e.g., 3 kills at level 3)
4. **Game Over** - When your hero dies, view your final statistics and start a new game

## Testing

The project includes a comprehensive test suite with 113 tests covering all game mechanics.

### Run All Tests

```bash
mix test
```

### Run Specific Test File

```bash
# Test hero mechanics
mix test test/super_dungeon_slaughter_ex/game/hero_test.exs

# Test monster mechanics
mix test test/super_dungeon_slaughter_ex/game/monster_test.exs

# Test game state
mix test test/super_dungeon_slaughter_ex/game/game_state_test.exs

# Test LiveView
mix test test/super_dungeon_slaughter_ex_web/live/game_live_test.exs
```

### Run Tests with Coverage

```bash
mix test --cover
```

### Test Summary

- **113 tests** covering all game mechanics
- **Hero Module** (30 tests) - Combat, leveling, statistics
- **Monster Module** (12 tests) - Spawning, Gaussian stats
- **Score Module** (6 tests) - Serialization, sorting
- **Repositories** (7 tests) - Monster and score persistence
- **GameState** (38 tests) - Full game flow and integration
- **LiveView** (20 tests) - UI rendering and event handling

See [TEST_SUMMARY.md](TEST_SUMMARY.md) for detailed test coverage information.

## Project Structure

```
lib/
├── super_dungeon_slaughter_ex/
│   ├── game/
│   │   ├── hero.ex              # Hero entity with stats & progression
│   │   ├── monster.ex           # Monster entity with Gaussian stats
│   │   └── game_state.ex        # Game state management
│   ├── repos/
│   │   ├── monster_repo.ex      # Monster template repository
│   │   └── score_repo.ex        # High score repository
│   └── score.ex                 # Score data model
├── super_dungeon_slaughter_ex_web/
│   ├── components/
│   │   └── game_components.ex   # Game-specific UI components
│   └── live/
│       └── game_live.ex         # Main game LiveView
priv/
└── data/
    ├── monsters.json            # Monster templates
    └── scores.json              # Persistent high scores
```

## Game Mechanics

### Combat

- **Hero Damage** - Random between damage_min and damage_max
- **Monster Damage** - Gaussian distribution based on damage_base ± damage_sigma
- **Healing** - Random between heal_min and heal_max (capped at max HP)

### Leveling

- **Threshold** - Kill N monsters at level N to advance
- **HP Growth** - Max HP increases by new level value
- **Damage Growth** - 10% increase per level (minimum +1)
- **Heal Growth** - 15% increase per level (minimum +1)

### Health Color Coding

- **Green** - HP > 66%
- **Yellow** - 33% < HP ≤ 66%
- **Red** - HP ≤ 33%

## Documentation

- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) - Comprehensive implementation plan
- [GAME_README.md](GAME_README.md) - Detailed game mechanics and architecture
- [TEST_SUMMARY.md](TEST_SUMMARY.md) - Complete test coverage documentation

## Development

### Code Quality

```bash
# Format code
mix format

# Run static analysis (if credo is added)
mix credo
```

### Adding New Monsters

Edit `priv/data/monsters.json`:

```json
{
  "MonsterName": {
    "min_level": 0,
    "max_level": 5,
    "avg_hp": 10.0,
    "hp_sigma": 2.0,
    "damage_base": 5.0,
    "damage_sigma": 1.0
  }
}
```

## Deployment

Ready to run in production? Please check the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Future Enhancements

The architecture supports easy addition of:
- Inventory system (items, weapons, armor)
- Consumables (potions, scrolls)
- Spells and magic system
- Multiplayer features
- Achievements

## Credits

- **Original Python Game** - Super Dungeon Slaughter
- **Phoenix Port** - Super Dungeon Slaughter EX
- **Framework** - Phoenix LiveView
- **Language** - Elixir

## License

This project is available for personal and educational use.

---

Enjoy slaying monsters! 🎮✨
