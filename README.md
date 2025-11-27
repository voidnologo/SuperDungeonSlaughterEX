# Super Dungeon Slaughter EX 🐉⚔️🧪

A retro-styled dungeon crawler web game built with Elixir Phoenix LiveView. This is a modern port of the Python CLI game "Super Dungeon Slaughter" featuring real-time reactive UI, turn-based combat, character progression, magical potions, and comprehensive statistics tracking.

## Features

- **Real-time Gameplay** - LiveView provides instant feedback without page reloads
- **Turn-based Combat** - Fight or rest to survive against increasingly powerful monsters
- **Character Progression** - Level up system with stat scaling
- **Boss Encounters** - Face powerful boss monsters every 10 levels with epic rewards
- **Floor Progression** - Advance through dungeon floors by defeating bosses
- **Inventory System** - Collect and manage potions with strategic 5-slot inventory
- **Healing & Damage Potions** - Three quality tiers (Minor, Normal, Major) with percentage-based effects
- **Potion Drops** - Randomly dropped potions from defeated monsters with varied flavors
- **21 Monster Types** - From weak Kobolds to fearsome Greater Dragons, plus 10 powerful bosses
- **Enhanced History** - Color-coded combat log with icons for different event types
- **Statistics Tracking** - Total damage dealt, health healed, kill count per monster type, and bosses defeated
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
5. **Boss Encounters**:
   - **Every 10 Levels** - Face a powerful boss at levels 10, 20, 30, etc.
   - **Epic Battles** - Bosses have ~3.5x HP and ~1.75x damage of regular monsters
   - **Visual Distinction** - Red pulsing border and special combat messages
   - **Full Heal** - Your HP is restored to maximum upon boss victory
   - **Guaranteed Reward** - Choose between a Major Healing or Major Damage potion
   - **Floor Progression** - Each boss defeated advances you to the next floor
6. **Leveling Up** - Kill N monsters at level N to advance (e.g., 3 kills at level 3)
7. **Game Over** - When your hero dies, view your final statistics and compare your score on the leaderboard

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

- **Hero Module**  - Combat, leveling, statistics, floor progression
- **Monster Module**  - Spawning, Gaussian stats, boss mechanics, difficulty scaling
- **Score Module** - Serialization, sorting
- **Repositories** - Monster and score persistence, boss spawning
- **GameState** - Full game flow, boss encounters, rewards, and integration
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

**Regular Monster:**
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

**Boss Monster:**
```json
{
  "Boss Name": {
    "min_level": 10,
    "max_level": 10,
    "avg_hp": 255.0,
    "hp_sigma": 0.0,
    "damage_base": 10.0,
    "damage_sigma": 0.0,
    "is_boss": true,
    "floor": 1
  }
}
```

Boss monsters have:
- **Fixed stats** (hp_sigma and damage_sigma should be 0)
- **min_level = max_level** for precise spawning
- **is_boss: true** flag
- **floor** number for progression tracking

## Deployment

Ready to run in production? Please check the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Game Mechanics

### Combat System
- **Hero Damage** - Random between damage_min and damage_max (scales with level)
- **Monster Damage** - Gaussian distribution based on monster strength
- **Healing** - Random between heal_min and heal_max (scales with level)
- **Counter-attacks** - Monsters strike back after Fight action (if alive)

### Boss Encounters
- **Spawn Frequency** - Every 10 levels (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
- **Boss Stats** - Fixed stats (no randomization) with ~3.5x HP and ~1.75x damage
- **Boss List**:
  - Level 10: **Goblin King** (Floor 1)
  - Level 20: **Ancient Lich** (Floor 2)
  - Level 30: **Infernal Drake** (Floor 3)
  - Level 40: **Storm Titan** (Floor 4)
  - Level 50: **Shadow Overlord** (Floor 5)
  - Level 60: **Frost Wyrm** (Floor 6)
  - Level 70: **Void Harbinger** (Floor 7)
  - Level 80: **Crimson Reaper** (Floor 8)
  - Level 90: **Abyssal Leviathan** (Floor 9)
  - Level 100: **Eternal Tyrant** (Floor 10)
- **Visual Distinction** - Red pulsing border around boss stats panel
- **Victory Rewards**:
  - Full HP restoration
  - Choice of Major Healing or Major Damage potion (guaranteed)
  - Advance to next dungeon floor
- **No Difficulty Scaling** - Boss stats remain the same regardless of difficulty setting

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
- **Event Icons** - Combat 🗡️, Healing ❤️, Victory ⭐, Items 🎁, Level Up 🎉, Death 💀, Boss Encounter ⚔️, Boss Victory 🏆
- **Separator Lines** - Visual breaks for major events like level ups and boss encounters

## Future Enhancements

The architecture supports easy addition of:
- **Equipment system** (weapons, armor)
- **More consumables** (scrolls, elixirs, buffs)
- **Spells and magic system**
- **Special abilities** and hero classes
- **Boss loot tables** with unique items
- **Difficulty modes** affecting boss scaling
- **Multiplayer features** and leaderboards
- **Achievements and challenges**
- **Endless mode** beyond floor 10

## Credits

- **Original Python Game** - Super Dungeon Slaughter
- **Phoenix Port** - Super Dungeon Slaughter EX
- **Framework** - Phoenix LiveView
- **Language** - Elixir

## License

This project is available for personal and educational use.

---

Enjoy slaying monsters! 🎮✨
