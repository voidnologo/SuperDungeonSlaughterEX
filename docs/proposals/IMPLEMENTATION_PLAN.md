# Super Dungeon Slaughter EX - Implementation Plan

## Executive Summary

This document outlines the plan to port the Python CLI game "Super Dungeon Slaughter" to an Elixir Phoenix LiveView web application. The new application will maintain the core game mechanics while presenting them through a modern, reactive web UI with retro video game aesthetics.

---

## 1. Project Overview

### 1.1 Source Analysis

The Python application is a well-structured CLI dungeon crawler with:
- **Core Entities**: Hero, Monster, Score
- **Game Mechanics**: Turn-based combat, leveling system, monster spawning
- **Data**: 11 monster types with Gaussian-distributed stats
- **Persistence**: JSON files for monsters and high scores
- **UI**: ANSI color-coded terminal with health indicators

### 1.2 Target Architecture

**Phoenix LiveView Application** with:
- Real-time reactive UI updates via WebSocket
- Retro video game visual theme (Tailwind CSS)
- Three-panel layout: Game History (center), Player Stats (right-top), Monster Stats (right-bottom)
- Two action buttons: REST (green) and FIGHT (red)
- Color-coded health indicators (red/yellow/green based on HP percentage)
- JSON file persistence for high scores (shared leaderboard)
- Fresh game state per browser session (stored in LiveView process)
- **Game statistics tracking**: Total damage dealt, health healed, and monster kill breakdown
- **Enhanced game over screen**: Full statistics display with "New Game?" restart button

---

## 2. Application Structure

### 2.1 Phoenix Project Setup

```
super_dungeon_slaughter_ex/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   └── test.exs
├── lib/
│   ├── super_dungeon_slaughter_ex/
│   │   ├── application.ex
│   │   ├── game/              # Core game logic
│   │   │   ├── hero.ex
│   │   │   ├── monster.ex
│   │   │   ├── combat.ex
│   │   │   ├── game_state.ex
│   │   │   └── stats.ex
│   │   ├── repos/             # Data persistence
│   │   │   ├── monster_repo.ex
│   │   │   └── score_repo.ex
│   │   └── score.ex
│   └── super_dungeon_slaughter_ex_web/
│       ├── components/
│       │   ├── core_components.ex
│       │   ├── game_components.ex     # Custom game UI components
│       │   └── layouts.ex
│       ├── controllers/
│       │   └── page_controller.ex
│       ├── live/
│       │   └── game_live.ex           # Main game LiveView
│       ├── endpoint.ex
│       └── router.ex
├── priv/
│   ├── static/
│   └── data/
│       ├── monsters.json
│       └── scores.json
├── test/
└── mix.exs
```

---

## 3. Data Models

### 3.1 Hero Module (`lib/super_dungeon_slaughter_ex/game/hero.ex`)

**Struct Definition:**
```elixir
defmodule SuperDungeonSlaughterEx.Game.Hero do
  @type t :: %__MODULE__{
    name: String.t(),
    level: pos_integer(),
    hp: non_neg_integer(),
    hp_max: pos_integer(),
    total_kills: non_neg_integer(),
    level_kills: non_neg_integer(),
    damage_min: non_neg_integer(),
    damage_max: non_neg_integer(),
    heal_min: pos_integer(),
    heal_max: pos_integer(),
    # Game statistics
    total_damage_dealt: non_neg_integer(),
    total_health_healed: non_neg_integer(),
    monsters_killed_by_type: %{String.t() => non_neg_integer()}
  }
end
```

**Key Functions:**
- `new(name)` - Create level 1 hero with starting stats and empty statistics
- `attack(hero, monster)` - Return {updated_hero, updated_monster, damage, message}
  - Increments `total_damage_dealt` by damage amount
- `take_damage(hero, damage)` - Return updated hero
- `rest(hero)` - Return {updated_hero, heal_amount, message}
  - Increments `total_health_healed` by heal amount
- `record_kill(hero, monster_name)` - Increment kills and monster-specific counter
  - Increments `total_kills`, `level_kills`, and `monsters_killed_by_type[monster_name]`
- `level_up(hero)` - Check if ready to level up, return updated hero
- `should_level_up?(hero)` - Check if level_kills threshold met
- `hp_percentage(hero)` - For color coding (0.0 to 1.0)
- `get_statistics(hero)` - Return formatted statistics map for game over screen

**Leveling Rules** (from Python):
- Level up when `level_kills == current_level` (e.g., kill 3 monsters at level 3)
- HP max increases by `level` on level up
- Damage min/max scale by 10% (minimum +1)
- Heal min/max scale by 15% (minimum +1)

**Starting Stats:**
- Level: 1
- HP: 10/10
- Damage: 0-3
- Heal: 1-4
- Statistics: All at 0, empty monsters_killed_by_type map

### 3.2 Monster Module (`lib/super_dungeon_slaughter_ex/game/monster.ex`)

**Struct Definition:**
```elixir
defmodule SuperDungeonSlaughterEx.Game.Monster do
  @type template :: %{
    name: String.t(),
    min_level: non_neg_integer(),
    max_level: pos_integer(),
    avg_hp: float(),
    hp_sigma: float(),
    damage_base: float(),
    damage_sigma: float()
  }

  @type t :: %__MODULE__{
    name: String.t(),
    hp: non_neg_integer(),
    hp_max: pos_integer(),
    damage_base: float(),
    damage_sigma: float()
  }
end
```

**Key Functions:**
- `from_template(template)` - Spawn instance with Gaussian HP (`:rand.normal/0`)
- `attack(monster, hero)` - Return {updated_hero, damage, message}
- `take_damage(monster, damage)` - Return updated monster
- `hp_percentage(monster)` - For color coding
- `defeated?(monster)` - Check if HP <= 0

**Gaussian Damage** (from Python):
- Use `:rand.normal/0` for Gaussian distribution
- Clamp damage to non-negative values

### 3.3 Score Module (`lib/super_dungeon_slaughter_ex/score.ex`)

**Struct Definition:**
```elixir
defmodule SuperDungeonSlaughterEx.Score do
  @type t :: %__MODULE__{
    name: String.t(),
    level: pos_integer(),
    kills: non_neg_integer()
  }
end
```

**Key Functions:**
- `new(name, level, kills)`
- `to_map(score)` - For JSON serialization
- `from_map(map)` - For JSON deserialization
- Sorted by level (desc), then kills (desc)

### 3.4 GameState Module (`lib/super_dungeon_slaughter_ex/game/game_state.ex`)

**Struct Definition:**
```elixir
defmodule SuperDungeonSlaughterEx.Game.GameState do
  alias SuperDungeonSlaughterEx.Game.{Hero, Monster}

  @type t :: %__MODULE__{
    hero: Hero.t(),
    monster: Monster.t(),
    history: [String.t()],  # Combat log messages
    game_over: boolean()
  }
end
```

**Key Functions:**
- `new(hero_name)` - Initialize game with hero and first monster
- `handle_fight(state)` - Execute fight action, update state, statistics, and history
- `handle_rest(state)` - Execute rest action, update state, statistics, and history
- `add_to_history(state, message)` - Prepend message to history (newest first)
- `check_game_over(state)` - Update game_over flag if hero defeated

**Note:** All combat actions update hero statistics (damage dealt, health healed, monsters killed)

### 3.5 Combat Module (`lib/super_dungeon_slaughter_ex/game/combat.ex`)

Pure functions for combat calculations:
- `execute_hero_attack(hero, monster)` - Return damage, messages
- `execute_monster_attack(monster, hero)` - Return damage, messages
- `execute_rest(hero)` - Return heal amount, message
- `defeated?(combatant)` - HP <= 0 check

---

## 4. Data Repositories

### 4.1 MonsterRepo (`lib/super_dungeon_slaughter_ex/repos/monster_repo.ex`)

**Responsibilities:**
- Load monsters.json at application startup (GenServer)
- Index monsters by level range for fast lookup
- Provide `get_monster_for_level(level)` with fallback logic

**Implementation:**
```elixir
defmodule SuperDungeonSlaughterEx.Repos.MonsterRepo do
  use GenServer

  # Client API
  def start_link(json_path)
  def get_monster_for_level(level)
  def get_all_templates()

  # Server callbacks
  def init(json_path)
  def handle_call({:get_monster, level}, _from, state)

  # Private
  defp load_monsters(path)
  defp index_by_level(templates)
  defp find_monsters_for_level(level, index)
end
```

**Startup:**
- Started in `Application.ex` supervision tree
- Reads `priv/data/monsters.json` on init
- Builds level index (e.g., `%{1 => ["Kobold", "Goblin"], 2 => [...]`)

### 4.2 ScoreRepo (`lib/super_dungeon_slaughter_ex/repos/score_repo.ex`)

**Responsibilities:**
- Load/save scores.json (GenServer with file locking)
- Maintain sorted in-memory list
- Provide top N scores

**Implementation:**
```elixir
defmodule SuperDungeonSlaughterEx.Repos.ScoreRepo do
  use GenServer

  # Client API
  def start_link(json_path)
  def add_score(score)
  def get_top_scores(limit \\ 10)

  # Server callbacks
  def init(json_path)
  def handle_call(:get_top, _from, state)
  def handle_cast({:add, score}, state)

  # Private
  defp load_scores(path)
  defp save_scores(scores, path)
  defp sort_scores(scores)
end
```

**Sorting Logic:**
- Primary: Level (descending)
- Secondary: Kills (descending)

---

## 5. LiveView Implementation

### 5.1 GameLive (`lib/super_dungeon_slaughter_ex_web/live/game_live.ex`)

**Responsibilities:**
- Manage game state in LiveView process
- Handle user actions (fight, rest)
- Render game UI
- Manage game over flow

**Mount:**
```elixir
def mount(_params, _session, socket) do
  # Prompt for hero name (or use default)
  socket =
    socket
    |> assign(:game_state, nil)
    |> assign(:show_name_prompt, true)
    |> assign(:high_scores, ScoreRepo.get_top_scores())

  {:ok, socket}
end
```

**Events:**
```elixir
def handle_event("create_hero", %{"name" => name}, socket)
def handle_event("fight", _, socket)
def handle_event("rest", _, socket)
def handle_event("new_game", _, socket)
def handle_event("save_score", _, socket)
```

**Update Flow:**
1. Receive event (fight/rest)
2. Update GameState via `GameState.handle_fight/1` or `GameState.handle_rest/1`
3. Check for level up, monster death, hero death
4. Update history
5. Re-render via socket assigns

### 5.2 Template Structure (`game_live.html.heex`)

**Layout:**
```heex
<div class="min-h-screen bg-gray-900 text-green-400 font-mono">
  <!-- Title -->
  <header class="text-center py-6">
    <h1 class="text-4xl font-bold text-red-500">Super Dungeon Slaughter EX</h1>
  </header>

  <div class="container mx-auto px-4">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <!-- Game History (spans 2 columns) -->
      <div class="lg:col-span-2">
        <.game_history history={@game_state.history} />
      </div>

      <!-- Right sidebar -->
      <div class="space-y-4">
        <!-- Player Stats -->
        <.hero_stats hero={@game_state.hero} />

        <!-- Monster Stats -->
        <.monster_stats monster={@game_state.monster} />
      </div>
    </div>

    <!-- Action Buttons (disabled when game over) -->
    <div class="flex gap-4 justify-center mt-8">
      <button
        phx-click="rest"
        disabled={@game_state.game_over}
        class="px-8 py-4 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed..."
      >
        REST
      </button>
      <button
        phx-click="fight"
        disabled={@game_state.game_over}
        class="px-8 py-4 bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed..."
      >
        FIGHT
      </button>
    </div>
  </div>

  <!-- Game Over Modal Overlay -->
  <%= if @game_state.game_over do %>
    <.game_over_stats hero={@game_state.hero} />
  <% end %>
</div>
```

### 5.3 Game Components (`game_components.ex`)

**HeroStats Component:**
```elixir
attr :hero, :map, required: true

def hero_stats(assigns) do
  ~H"""
  <div class="border-2 border-orange-500 p-4 rounded bg-gray-800">
    <h2 class="text-xl font-bold text-orange-400 mb-3">Player Stats</h2>
    <div class="space-y-2">
      <div class="flex justify-between">
        <span>Kill Count:</span>
        <span class="text-yellow-400"><%= @hero.total_kills %></span>
      </div>
      <div class="flex justify-between">
        <span>Level:</span>
        <span class="text-yellow-400"><%= @hero.level %></span>
      </div>
      <div>
        <div class="flex justify-between mb-1">
          <span>HP:</span>
          <span class={hp_color(@hero)}>
            <%= @hero.hp %>/<%= @hero.hp_max %>
          </span>
        </div>
        <.hp_bar percentage={hp_percentage(@hero)} />
      </div>
    </div>
  </div>
  """
end
```

**MonsterStats Component:**
```elixir
attr :monster, :map, required: true

def monster_stats(assigns) do
  ~H"""
  <div class="border-2 border-orange-500 p-4 rounded bg-gray-800">
    <h2 class="text-xl font-bold text-orange-400 mb-3">Monster Stats</h2>
    <div class="space-y-2">
      <div class="text-lg font-semibold text-purple-400">
        <%= @monster.name %>
      </div>
      <div>
        <div class="flex justify-between mb-1">
          <span>HP:</span>
          <span class={hp_color(@monster)}>
            <%= @monster.hp %>/<%= @monster.hp_max %>
          </span>
        </div>
        <.hp_bar percentage={hp_percentage(@monster)} />
      </div>
    </div>
  </div>
  """
end
```

**GameHistory Component:**
```elixir
attr :history, :list, required: true

def game_history(assigns) do
  ~H"""
  <div class="border-2 border-gray-700 p-4 rounded bg-black h-[600px] overflow-y-auto">
    <div class="space-y-1 font-mono text-sm">
      <%= for message <- @history do %>
        <div class="text-green-300"><%= message %></div>
      <% end %>
    </div>
  </div>
  """
end
```

**HP Bar Component:**
```elixir
attr :percentage, :float, required: true

def hp_bar(assigns) do
  ~H"""
  <div class="w-full bg-gray-700 rounded h-4">
    <div
      class={"h-full rounded transition-all duration-300 #{hp_bar_color(@percentage)}"}
      style={"width: #{@percentage * 100}%"}
    />
  </div>
  """
end

defp hp_bar_color(percentage) when percentage > 0.66, do: "bg-green-500"
defp hp_bar_color(percentage) when percentage > 0.33, do: "bg-yellow-500"
defp hp_bar_color(_), do: "bg-red-500"

defp hp_color(combatant) do
  case hp_percentage(combatant) do
    p when p > 0.66 -> "text-green-400"
    p when p > 0.33 -> "text-yellow-400"
    _ -> "text-red-400"
  end
end

defp hp_percentage(%{hp: hp, hp_max: max}) when max > 0, do: hp / max
defp hp_percentage(_), do: 0.0
```

**GameOverStats Component:**
```elixir
attr :hero, :map, required: true

def game_over_stats(assigns) do
  ~H"""
  <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
    <div class="bg-gray-800 border-4 border-red-500 rounded-lg p-8 max-w-2xl w-full mx-4">
      <h2 class="text-4xl font-bold text-red-500 text-center mb-6">Game Over!</h2>

      <div class="bg-black p-6 rounded mb-6 space-y-3 font-mono">
        <h3 class="text-2xl text-yellow-400 mb-4">Final Statistics</h3>

        <div class="flex justify-between text-green-400">
          <span>Level Achieved:</span>
          <span class="text-yellow-300 font-bold"><%= @hero.level %></span>
        </div>

        <div class="flex justify-between text-green-400">
          <span>Monsters Killed:</span>
          <span class="text-yellow-300 font-bold"><%= @hero.total_kills %></span>
        </div>

        <div class="flex justify-between text-green-400">
          <span>Total Damage Dealt:</span>
          <span class="text-yellow-300 font-bold"><%= @hero.total_damage_dealt %></span>
        </div>

        <div class="flex justify-between text-green-400">
          <span>Total Health Healed:</span>
          <span class="text-yellow-300 font-bold"><%= @hero.total_health_healed %></span>
        </div>

        <div class="mt-6">
          <h4 class="text-xl text-purple-400 mb-3">Monster Kill Breakdown</h4>
          <div class="space-y-1">
            <%= for {monster_name, count} <- sort_monster_kills(@hero.monsters_killed_by_type) do %>
              <div class="flex justify-between text-green-300">
                <span><%= monster_name %>:</span>
                <span class="text-yellow-300"><%= count %></span>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <button
        phx-click="new_game"
        class="w-full py-4 bg-green-600 hover:bg-green-700 text-white text-2xl font-bold rounded transition-colors"
      >
        New Game?
      </button>
    </div>
  </div>
  """
end

defp sort_monster_kills(kills_map) do
  kills_map
  |> Enum.sort_by(fn {_name, count} -> count end, :desc)
end
```

---

## 6. Styling - Retro Video Game Theme

### 6.1 Color Scheme

**Base Colors:**
- Background: Dark gray/black (`bg-gray-900`, `bg-black`)
- Primary text: Bright green (`text-green-400`) - classic terminal
- Accents: Orange (`border-orange-500`), Red (`text-red-500`)
- Monster names: Purple/Magenta (`text-purple-400`)

**Health Colors:**
- High (>66%): Green (`text-green-400`, `bg-green-500`)
- Medium (33-66%): Yellow (`text-yellow-400`, `bg-yellow-500`)
- Low (<33%): Red (`text-red-400`, `bg-red-500`)

**Buttons:**
- REST: Green gradient (`bg-green-600 hover:bg-green-700`)
- FIGHT: Red gradient (`bg-red-600 hover:bg-red-700`)
- Large, chunky buttons with bold text

### 6.2 Typography

- Font: `font-mono` (monospace for retro terminal feel)
- Title: Large, bold, retro style
- Game text: Small-medium for readability
- Stats: Clear hierarchy with labels and values

### 6.3 Additional Polish

- Scanline effect (optional): CSS overlay for CRT monitor feel
- Glow effects on buttons (optional): `shadow-lg shadow-green-500/50`
- Border styles: Thick borders (`border-2`, `border-4`)
- Rounded corners: Minimal (`rounded`)

---

## 7. Game Flow & Features

### 7.1 Initial Load

1. User visits root path `/`
2. Prompt for hero name (modal or inline form)
3. Create Hero, spawn first Monster
4. Initialize GameState with empty history
5. Render game UI

### 7.2 Combat Flow

**Fight Action:**
1. Hero attacks monster (calculate damage)
2. Update hero's `total_damage_dealt` statistic
3. Add attack message to history
4. If monster defeated:
   - Increment kill counters (`total_kills`, `level_kills`)
   - Update `monsters_killed_by_type[monster_name]`
   - Check for level up (show message in history)
   - Spawn new monster
   - Add level up + new monster messages to history
5. If monster alive:
   - Monster attacks hero
   - Add monster attack message to history
6. If hero defeated:
   - Set game_over = true
   - Show game statistics screen
   - Auto-save score to ScoreRepo
   - Show "New Game?" button

**Rest Action:**
1. Hero heals (calculate heal amount)
2. Update hero's `total_health_healed` statistic
3. Add heal message to history
4. Monster attacks hero
5. Add monster attack message to history
6. Check if hero defeated (same as above)

### 7.3 Game Over Flow

**When Hero Dies:**
1. Set `game_over = true` in GameState
2. Display death message in history
3. Show game statistics screen with:
   - **Level Achieved:** `hero.level`
   - **Monsters Killed:** `hero.total_kills`
   - **Total Damage Dealt:** `hero.total_damage_dealt`
   - **Total Health Healed:** `hero.total_health_healed`
   - **Monster Kill Breakdown:** List of each monster type and count
     - Format: "Goblin: 5, Orc: 3, Kobold: 12" (sorted by count descending)
4. Automatically save score to ScoreRepo
5. Show "New Game?" button to restart

**Game Statistics Display Format:**
```
Game Over!

Final Statistics:
- Level Achieved: 4
- Monsters Killed: 25
- Total Damage Dealt: 347
- Total Health Healed: 89

Monster Kill Breakdown:
- Goblin: 12
- Orc: 7
- Kobold: 4
- Werebat: 2

[New Game?]
```

**New Game:**
- Reset game state completely
- Prompt for new hero name (or reuse previous)
- Fresh Monster spawn
- Clear history
- Reset all statistics to 0

### 7.4 High Scores Display

**Options:**
1. Dedicated `/scores` route with simple list
2. Modal overlay on game page (triggered by button)
3. Side panel (if space permits)

**Recommendation:** Small "View High Scores" button that opens modal overlay showing top 10, then close to return to game.

---

## 8. Future Extensibility

Design considerations for future features:

### 8.1 Inventory System

**Preparation:**
- Keep GameState flexible with optional `:inventory` field
- Define `SuperDungeonSlaughterEx.Game.Item` protocol
- Separate inventory UI component slot in layout

**Items to Support:**
- Weapons (modify damage_min/max)
- Armor (reduce incoming damage)
- Potions (instant healing, effects)
- Spells (special attacks, buffs)

### 8.2 UI Extensions

**Inventory Panel:**
- Add 4th panel below monster stats
- Grid of item slots
- Click to equip/use

**Action Extensions:**
- "Use Item" button (enabled when items available)
- Drag-and-drop (future enhancement)

### 8.3 Data Model Extensions

**Hero Extensions:**
```elixir
defmodule Hero do
  # Future fields:
  # equipped_weapon: Item.t() | nil
  # equipped_armor: Item.t() | nil
  # inventory: [Item.t()]
  # mana: non_neg_integer()
end
```

**Item Protocol:**
```elixir
defprotocol SuperDungeonSlaughterEx.Game.Item do
  def apply_effect(item, hero)
  def description(item)
end
```

---

## 9. Implementation Phases

### Phase 1: Project Setup
1. Generate Phoenix project with LiveView
2. Configure Tailwind CSS
3. Set up project structure (folders)
4. Create `priv/data/` and copy JSON files

### Phase 2: Core Data Models
1. Implement Hero module with all functions
2. Implement Monster module with Gaussian randomization
3. Implement Score module
4. Write unit tests for models

### Phase 3: Repositories
1. Implement MonsterRepo GenServer
2. Implement ScoreRepo GenServer
3. Add to Application supervision tree
4. Test repository functions

### Phase 4: Game Logic
1. Implement GameState module
2. Implement Combat module (pure functions)
3. Write tests for game state transitions
4. Test level-up logic, monster spawning, game over

### Phase 5: LiveView & Components
1. Create GameLive with basic mount
2. Implement hero name prompt flow
3. Create game_components.ex (HeroStats, MonsterStats, GameHistory)
4. Wire up fight/rest event handlers
5. Implement game over flow

### Phase 6: Styling
1. Apply retro color scheme
2. Style game history terminal
3. Style stat panels with borders
4. Create large action buttons
5. Add responsive layout
6. Polish with animations/transitions

### Phase 7: High Scores
1. Add "View High Scores" feature
2. Create scores display component
3. Wire up to ScoreRepo
4. Test score persistence

### Phase 8: Testing & Polish
1. Manual testing of full game flow
2. Edge case testing (hero death, level thresholds)
3. Performance testing (history length limits)
4. Cross-browser testing
5. Add any missing animations/feedback

### Phase 9: Documentation
1. Update README with setup instructions
2. Document game mechanics
3. Add screenshots
4. Deployment guide (optional)

---

## 10. Technical Considerations

### 10.1 Randomization

**Python uses:**
- `random.randint(min, max)` for hero attacks/heals
- `random.gauss(mu, sigma)` for monster HP and damage

**Elixir equivalents:**
- `:rand.uniform(max - min + 1) + min - 1` for uniform random
- `:rand.normal(mu, sigma)` for Gaussian (available in OTP 25+)

**Note:** Seed the random number generator in tests for reproducibility.

### 10.2 Message History Management

**Considerations:**
- History list can grow unbounded
- Limit to last N messages (e.g., 100-200)
- Use `Enum.take(history, @max_history)` after each addition

**Optimization:**
- Store as list with newest messages first
- Reverse for display: `Enum.reverse(history)`
- Or use `:queue` module for efficient FIFO

### 10.3 File Locking for scores.json

**Challenge:** Multiple simultaneous players writing scores

**Solution:**
- ScoreRepo is a GenServer (serializes all writes)
- Use `File.open/3` with `:exclusive` lock
- GenServer state is source of truth
- Periodic flush to disk or on each add

### 10.4 Health Percentage Calculation

**Python implementation:**
```python
ratio = hp / max_hp if max_hp > 0 else 0
colors = [RED, YELLOW, GREEN]
color = colors[bisect([0.33, 0.66], ratio)]
```

**Elixir implementation:**
```elixir
defp hp_percentage(%{hp: hp, hp_max: max}) when max > 0, do: hp / max
defp hp_percentage(_), do: 0.0

defp hp_color(percentage) when percentage > 0.66, do: "text-green-400"
defp hp_color(percentage) when percentage > 0.33, do: "text-yellow-400"
defp hp_color(_), do: "text-red-400"
```

### 10.5 LiveView Process Lifecycle

**Per-Session State:**
- Each browser tab = separate LiveView process
- Game state lives in process memory
- Game state lost when tab closed (as designed)
- High scores persist via ScoreRepo

**Cleanup:**
- No special cleanup needed (process terminates)
- Could add `terminate/2` callback for analytics

---

## 11. Testing Strategy

### 11.1 Unit Tests

**Models:**
- Hero: level up calculation, attack/heal ranges, stat scaling
- Monster: Gaussian distribution, attack calculation
- Score: validation, sorting

**Repositories:**
- MonsterRepo: level-based lookup, fallback logic
- ScoreRepo: add/retrieve, sorting, persistence

**GameState:**
- Fight flow (kill, level up, new monster)
- Rest flow
- Game over detection
- History management

### 11.2 Integration Tests

**LiveView:**
- Mount with hero name
- Fight button triggers state update
- Rest button triggers state update
- Game over flow
- High scores display

### 11.3 Property-Based Tests

**Consider using StreamData for:**
- Hero stat scaling always increases (or minimum +1)
- Monster HP always >= 1
- Damage always non-negative
- Score sorting maintains invariants

---

## 12. Deployment Considerations

### 12.1 Production Checklist

- [ ] Configure secret_key_base
- [ ] Set up production database (if used)
- [ ] Ensure `priv/data/scores.json` is writable
- [ ] Configure proper logging
- [ ] Set up SSL/TLS
- [ ] Configure CDN for static assets
- [ ] Set appropriate BEAM VM flags

### 12.2 Hosting Options

- **Fly.io**: Elixir-friendly, global edge
- **Gigalixir**: Specialized for Phoenix
- **Heroku**: Easy deployment
- **Self-hosted**: VPS with systemd

### 12.3 Scaling Notes

- Current design: Single-node, file-based scores
- For multi-node: Move scores to database or distributed cache
- LiveView scales well (each connection is a process)
- Consider rate limiting fight/rest actions to prevent abuse

---

## 13. Code Quality Standards

### 13.1 Elixir Best Practices

- **Naming:** snake_case for functions/variables, PascalCase for modules
- **Pattern Matching:** Prefer pattern matching over conditionals
- **Pipelines:** Use `|>` for data transformations
- **Documentation:** @moduledoc and @doc for all public functions
- **Typespecs:** @type and @spec for all public functions
- **Formatting:** Use `mix format` consistently

### 13.2 SOLID Principles

**Single Responsibility:**
- Each module has one clear purpose
- Combat logic separate from state management
- Repositories handle only data access

**Open/Closed:**
- Use protocols for future item system
- GameState extensible via optional fields

**Liskov Substitution:**
- Hero and Monster both implement "Combatant" behavior
- Consistent interface for attack/take_damage

**Interface Segregation:**
- Separate repos for Monsters and Scores
- Small, focused component functions

**Dependency Inversion:**
- GameState depends on Monster/Hero abstractions
- Repos injected via Application supervision tree

### 13.3 DRY Principle

- Shared HP percentage calculation
- Shared color coding logic (helper functions)
- Reusable component functions
- Combat logic centralized in Combat module

---

## 14. Key Differences from Python Version

### 14.1 Structural Changes

| Aspect | Python (CLI) | Elixir (LiveView) |
|--------|--------------|-------------------|
| **UI** | Terminal with prompts | Web UI with buttons |
| **Commands** | 7 commands (fight, rest, look, scores, escape, quit, help) | 2 buttons (Fight, Rest) |
| **State** | Single game loop | LiveView process per session |
| **History** | Printed to stdout | Scrollable div |
| **Stats Display** | Dynamic prompt | Always visible panels |
| **Game Over** | Exit loop | Show modal + restart button |

### 14.2 Removed Features

- **Look command**: Stats always visible, no need to inspect
- **Escape vs Quit**: Scores auto-saved on death
- **Help command**: UI is self-explanatory
- **Yes/No prompts**: Replaced with buttons

### 14.3 Enhanced Features

- **Real-time UI**: Immediate feedback via LiveView
- **Visual polish**: Color-coded health bars, retro aesthetics
- **Shared leaderboard**: All players see same high scores
- **Responsive layout**: Works on mobile/tablet/desktop

---

## 15. Open Questions & Decisions

### 15.1 Resolved

- ✅ Persistence: Fresh game per session, JSON for scores
- ✅ Leaderboard: Shared across all players
- ✅ UI Features: Minimal (Fight/Rest), game over with restart

### 15.2 Deferred to Implementation

- **History length limit**: Recommend 200 messages
- **Name validation**: Allow duplicates? Max length?
- **Score display**: Modal overlay or separate route?
- **Animation timing**: How long for HP bar transitions?
- **Mobile layout**: Single column or keep grid?

---

## 16. Success Criteria

### 16.1 Functional Requirements

- ✅ Hero creation with custom name
- ✅ Turn-based combat (Fight action)
- ✅ Healing mechanic (Rest action)
- ✅ Leveling system with stat progression
- ✅ 11 monster types with appropriate level ranges
- ✅ Health-based color coding (red/yellow/green)
- ✅ Game over detection and restart
- ✅ High score persistence across sessions
- ✅ Scrollable game history
- ✅ Game statistics tracking (damage dealt, health healed, monster kill breakdown)
- ✅ Game over screen with full statistics display
- ✅ Auto-save score on death

### 16.2 Non-Functional Requirements

- ✅ Retro video game aesthetic
- ✅ Clean, maintainable Elixir code
- ✅ SOLID principles applied
- ✅ DRY principle applied
- ✅ Responsive design
- ✅ Fast, reactive UI updates
- ✅ Extensible for future features (inventory, items)

### 16.3 Quality Gates

- All unit tests passing
- No compiler warnings
- `mix format` applied
- `mix credo` clean (or justified exceptions)
- Manual testing of full game flow
- Cross-browser compatibility verified

---

## 17. Timeline Estimate

**Total Effort:** Approximately 15-20 hours of focused development

**Phase Breakdown:**
1. **Project Setup** - 1 hour
2. **Core Data Models** - 3 hours
3. **Repositories** - 2 hours
4. **Game Logic** - 3 hours
5. **LiveView & Components** - 4 hours
6. **Styling** - 2 hours
7. **High Scores** - 1 hour
8. **Testing & Polish** - 3 hours
9. **Documentation** - 1 hour

**Note:** This excludes learning curve for Elixir/Phoenix if unfamiliar.

---

## 18. Next Steps

1. **Review this plan** - Discuss any questions or concerns
2. **Set up Phoenix project** - Run `mix phx.new` with LiveView
3. **Begin Phase 1** - Project structure and configuration
4. **Iterative development** - Implement phase by phase
5. **Continuous testing** - Write tests alongside code
6. **Regular check-ins** - Demo each phase completion

---

## 19. Conclusion

This implementation plan provides a comprehensive roadmap for porting Super Dungeon Slaughter from Python CLI to Elixir Phoenix LiveView. The design maintains the core game mechanics while leveraging LiveView's reactive capabilities and modern web UI patterns.

The architecture is clean, maintainable, and extensible, following SOLID and DRY principles. The retro video game aesthetic will provide a nostalgic, engaging user experience while the technical implementation ensures performance and scalability.

Future enhancements (inventory, items, spells) are accommodated in the design without requiring major refactoring.

**Ready to begin implementation!**
