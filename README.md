# Super Dungeon Slaughter EX 🐉⚔️🧪

A retro-styled dungeon crawler web game built with Elixir Phoenix LiveView. This is a modern port of the Python CLI game "Super Dungeon Slaughter" featuring real-time reactive UI, turn-based combat, character progression, magical potions, and comprehensive statistics tracking.

## Features

- **Real-time Gameplay** - LiveView provides instant feedback without page reloads
- **Turn-based Combat** - Fight or rest to survive against increasingly powerful monsters
- **Character Progression** - Level up system with stat scaling
- **Inventory System** - Collect and manage potions with strategic 5-slot inventory
- **Healing & Damage Potions** - Three quality tiers (Minor, Normal, Major) with percentage-based effects
- **Potion Drops** - Randomly dropped potions from defeated monsters with varied flavors
- **11 Monster Types** - From weak Kobolds to fearsome Greater Dragons
- **Enhanced History** - Color-coded combat log with icons for different event types
- **Statistics Tracking** - Total damage dealt, health healed, and kill count per monster type
- **Game Over Screen** - Comprehensive statistics display on death
- **High Score System** - Persistent leaderboard stored in JSON
- **Retro Aesthetic** - Terminal-style text with color-coded events and health indicators

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
   - **USE POTION** - Click a potion in your inventory to use it
3. **Inventory Management**:
   - **5 Inventory Slots** - Limited space forces strategic decisions
   - **Starting Potion** - Begin with 1 Normal Healing Potion
   - **Potion Drops** - 10% chance to drop from defeated monsters
   - **Full Inventory** - Swap potions when inventory is full
4. **Potion Types**:
   - **Healing Potions** - Restore health (25%, 50%, or 100% of max HP)
   - **Damage Potions** - Throw at monsters (25%, 50%, or 100% of monster HP)
   - **Quality Tiers** - Minor (test tube 🧪), Normal (flask ⚗️), Major (large container 🏺)
   - **Flavors** - Damage potions come in Fire, Acid, Lightning, Poison, Frost, Arcane, Shadow, and Radiant
5. **Leveling Up** - Kill N monsters at level N to advance (e.g., 3 kills at level 3)
6. **Game Over** - When your hero dies, view your final statistics and compare your score on the leaderboard

## Testing

The project includes a comprehensive test suite covering all game mechanics.

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

- **Hero Module**  - Combat, leveling, statistics
- **Monster Module**  - Spawning, Gaussian stats
- **Score Module** - Serialization, sorting
- **Repositories** - Monster and score persistence
- **GameState** - Full game flow and integration
- **LiveView**  - UI rendering and event handling

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

## Game Mechanics

### Combat System
- **Hero Damage** - Random between damage_min and damage_max (scales with level)
- **Monster Damage** - Gaussian distribution based on monster strength
- **Healing** - Random between heal_min and heal_max (scales with level)
- **Counter-attacks** - Monsters strike back after Fight action (if alive)

### Potion System
- **Drop Chance** - 10% total (5% Minor, 3% Normal, 2% Major)
- **Healing Effect** - Restores percentage of max HP (capped at maximum)
- **Damage Effect** - Deals percentage of monster's current HP
- **Inventory Limit** - 5 slots encourages strategic use
- **Monster Counter** - Using damage potion triggers monster counter-attack

### Leveling System
- **Threshold** - Kill N monsters at level N to advance
- **HP Growth** - Max HP increases by new level value
- **Damage Growth** - 10% increase per level (minimum +1)
- **Heal Growth** - 15% increase per level (minimum +1)

### Visual Feedback
- **Health Colors** - Green (>66%), Yellow (33-66%), Red (≤33%)
- **Event Icons** - Combat 🗡️, Healing ❤️, Victory ⭐, Items 🎁, Level Up 🎉, Death 💀
- **Separator Lines** - Visual breaks for major events like level ups

## Future Enhancements

The architecture supports easy addition of:
- Equipment system (weapons, armor)
- More consumables (scrolls, elixirs)
- Spells and magic system
- Special abilities
- Multiplayer features
- Achievements and challenges

## Credits

- **Original Python Game** - Super Dungeon Slaughter
- **Phoenix Port** - Super Dungeon Slaughter EX
- **Framework** - Phoenix LiveView
- **Language** - Elixir

## License

This project is available for personal and educational use.

---

Enjoy slaying monsters! 🎮✨
