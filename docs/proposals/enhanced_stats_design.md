# Enhanced Stat Tracking Dashboard - Design Document

**Date:** 2025-11-27
**Status:** Design phase
**Priority:** High

---

## Overview

Expand the existing statistics system to provide comprehensive analytics across both individual runs and lifetime performance. Create a dedicated stats dashboard that helps players understand their performance, track improvements, and discover interesting patterns in their gameplay.

---

## Goals

1. **Rich Data**: Track meaningful statistics beyond basic kills/damage
2. **Lifetime Progress**: Persistent stats across all playthroughs
3. **Engagement**: Give players reasons to review and improve
4. **Performance Insights**: Help players understand their playstyle
5. **Achievement Foundation**: Lay groundwork for future achievement system

---

## Current System Analysis

### Existing Per-Run Stats (in Hero module)
```elixir
- total_damage_dealt: non_neg_integer()
- total_health_healed: non_neg_integer()
- monsters_killed_by_type: %{String.t() => non_neg_integer()}
- total_kills: non_neg_integer()
- level: pos_integer()
```

**Displayed at Game Over:**
- Level achieved
- Monsters killed
- Total damage dealt
- Total health healed
- Monster kill breakdown

### Limitations
- No historical data (only current run)
- No efficiency metrics
- No comparison to past runs
- No records (highest damage, longest streak, etc.)
- No aggregate statistics

---

## Proposed Statistics

### Per-Run Stats (Enhanced)

**Combat Statistics:**
```elixir
- total_damage_dealt: non_neg_integer()           # Existing
- highest_single_damage: non_neg_integer()        # NEW
- total_attacks: non_neg_integer()                # NEW
- average_damage_per_attack: float()              # Calculated

- total_damage_taken: non_neg_integer()           # NEW
- total_monster_damage: non_neg_integer()         # NEW (before mitigation)
```

**Survival Statistics:**
```elixir
- total_health_healed: non_neg_integer()          # Existing
- heal_from_resting: non_neg_integer()            # NEW
- heal_from_potions: non_neg_integer()            # NEW
- total_rests: non_neg_integer()                  # NEW
- close_calls: non_neg_integer()                  # NEW (survived with HP < 10)
- perfect_fights: non_neg_integer()               # NEW (no damage taken)
```

**Resource Statistics:**
```elixir
- potions_used_healing: non_neg_integer()         # NEW
- potions_used_damage: non_neg_integer()          # NEW
- potions_found: non_neg_integer()                # NEW
- potions_declined: non_neg_integer()             # NEW (inventory full)
```

**Progression Statistics:**
```elixir
- total_kills: non_neg_integer()                  # Existing
- monsters_killed_by_type: map()                  # Existing
- bosses_defeated: non_neg_integer()              # NEW (from boss feature)
- highest_floor_reached: pos_integer()            # NEW (from boss feature)
- levels_gained: non_neg_integer()                # NEW (final_level - 1)
```

**Efficiency Metrics (Calculated):**
```elixir
- damage_per_turn: float()                        # total_damage / (attacks + rests)
- healing_efficiency: float()                     # health_healed / max_possible_healing
- survival_time: non_neg_integer()                # total turns survived
- kills_per_level: float()                        # total_kills / level
```

### Lifetime Stats (Persistent)

**Aggregate Statistics:**
```elixir
- total_games_played: non_neg_integer()
- total_deaths: non_neg_integer()
- total_victories: non_neg_integer()              # (if win condition exists)

- lifetime_damage_dealt: non_neg_integer()
- lifetime_healing_done: non_neg_integer()
- lifetime_kills: non_neg_integer()
- lifetime_bosses_defeated: non_neg_integer()
```

**Record Statistics:**
```elixir
- highest_level_ever: pos_integer()
- highest_damage_single_hit: non_neg_integer()
- longest_survival: non_neg_integer()             # Most turns in one game
- most_kills_single_game: non_neg_integer()
- most_damage_single_game: non_neg_integer()
```

**Monster Statistics:**
```elixir
- lifetime_monsters_killed_by_type: map()
- favorite_victim: String.t()                     # Most killed monster type
- nemesis: String.t()                             # Most deaths to (requires death tracking)
- rarest_monster_killed: String.t()               # Based on encounter rates
```

**Difficulty Statistics:**
```elixir
- games_by_difficulty: %{:easy => int, :normal => int, :hard => int}
- highest_level_by_difficulty: %{:easy => int, :normal => int, :hard => int}
- wins_by_difficulty: map()
```

**Recent Performance:**
```elixir
- last_10_runs: [RunSummary.t()]                  # Brief summaries of recent games
- current_streak: non_neg_integer()               # Consecutive games played
- best_streak_level: pos_integer()                # Highest level in current streak
```

---

## Data Model

### StatsRepo (NEW)

GenServer for managing persistent lifetime statistics:

```elixir
defmodule SuperDungeonSlaughterEx.Repos.StatsRepo do
  use GenServer

  @type lifetime_stats :: %{
    # Aggregate stats
    total_games_played: non_neg_integer(),
    total_deaths: non_neg_integer(),
    lifetime_damage_dealt: non_neg_integer(),
    lifetime_healing_done: non_neg_integer(),
    lifetime_kills: non_neg_integer(),
    lifetime_bosses_defeated: non_neg_integer(),

    # Records
    highest_level_ever: pos_integer(),
    highest_damage_single_hit: non_neg_integer(),
    longest_survival: non_neg_integer(),
    most_kills_single_game: non_neg_integer(),
    most_damage_single_game: non_neg_integer(),

    # Monster stats
    lifetime_monsters_killed_by_type: %{String.t() => non_neg_integer()},

    # Difficulty stats
    games_by_difficulty: %{atom() => non_neg_integer()},
    highest_level_by_difficulty: %{atom() => pos_integer()},

    # Recent history
    last_10_runs: [RunSummary.t()],
    current_streak: non_neg_integer()
  }

  # Client API
  def start_link(json_path)
  def get_lifetime_stats()
  def record_game_completion(game_state)
  def get_records()
  def get_recent_runs()
end
```

**Persistence:**
- Stored in `priv/data/lifetime_stats.json`
- Loaded on application start
- Saved after each game completion

### RunSummary (NEW)

Brief summary of a completed game for history:

```elixir
defmodule SuperDungeonSlaughterEx.Stats.RunSummary do
  @type t :: %__MODULE__{
    timestamp: DateTime.t(),
    hero_name: String.t(),
    difficulty: atom(),
    final_level: pos_integer(),
    total_kills: non_neg_integer(),
    bosses_defeated: non_neg_integer(),
    cause_of_death: String.t()  # Monster name that killed hero
  }
end
```

### Hero Module Extensions

Add fields for enhanced stat tracking:

```elixir
defmodule SuperDungeonSlaughterEx.Game.Hero do
  @type t :: %__MODULE__{
    # ... existing fields ...

    # Combat stats
    highest_single_damage: non_neg_integer(),
    total_attacks: non_neg_integer(),
    total_damage_taken: non_neg_integer(),

    # Survival stats
    heal_from_resting: non_neg_integer(),
    heal_from_potions: non_neg_integer(),
    total_rests: non_neg_integer(),
    close_calls: non_neg_integer(),
    perfect_fights: non_neg_integer(),

    # Resource stats
    potions_used_healing: non_neg_integer(),
    potions_used_damage: non_neg_integer(),
    potions_found: non_neg_integer(),
    potions_declined: non_neg_integer(),

    # Progression stats
    bosses_defeated: non_neg_integer(),
    highest_floor_reached: pos_integer()
  }

  # New functions
  def get_detailed_statistics(hero)
  def record_attack(hero, damage)
  def record_damage_taken(hero, damage)
  def record_rest(hero, heal_amount)
  def record_potion_use(hero, potion_type)
  def record_close_call(hero)
  def record_perfect_fight(hero)
end
```

---

## UI Design

### Stats Dashboard Location

**Option A: Dedicated Route**
- New route `/stats`
- Separate page for stats
- Link from main game page

**Option B: Modal Overlay**
- "View Stats" button on game page
- Modal with tabs for different stat categories
- More integrated with game flow

**Option C: Expandable Panel**
- Collapsible panel on main game page
- Toggle to show/hide stats
- Always accessible

**Recommendation: Option B (Modal with Tabs)**
- Doesn't navigate away from game
- Can organize stats into categories
- Consistent with high scores display

### Dashboard Layout

**Modal Structure:**
```
┌─────────────────────────────────────┐
│  📊 Statistics Dashboard      [X]   │
├─────────────────────────────────────┤
│ [Current Run] [Lifetime] [Records]  │  ← Tabs
├─────────────────────────────────────┤
│                                     │
│  [Tab Content Area]                 │
│                                     │
│  - Combat Stats                     │
│  - Survival Stats                   │
│  - Resource Usage                   │
│  - Monster Breakdown                │
│                                     │
└─────────────────────────────────────┘
```

### Tab 1: Current Run Stats

```heex
def current_run_stats(assigns) do
  ~H"""
  <div class="space-y-6">
    <!-- Combat Statistics -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-red-400 mb-3">⚔️ Combat Statistics</h3>
      <div class="grid grid-cols-2 gap-3 text-sm">
        <.stat_row label="Total Damage Dealt" value={@hero.total_damage_dealt} />
        <.stat_row label="Highest Hit" value={@hero.highest_single_damage} />
        <.stat_row label="Total Attacks" value={@hero.total_attacks} />
        <.stat_row
          label="Avg Damage/Attack"
          value={format_float(@hero.total_damage_dealt / max(@hero.total_attacks, 1))}
        />
        <.stat_row label="Damage Taken" value={@hero.total_damage_taken} />
        <.stat_row label="Perfect Fights" value={@hero.perfect_fights} />
      </div>
    </div>

    <!-- Survival Statistics -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-green-400 mb-3">❤️ Survival Statistics</h3>
      <div class="grid grid-cols-2 gap-3 text-sm">
        <.stat_row label="Total Healing" value={@hero.total_health_healed} />
        <.stat_row label="From Resting" value={@hero.heal_from_resting} />
        <.stat_row label="From Potions" value={@hero.heal_from_potions} />
        <.stat_row label="Times Rested" value={@hero.total_rests} />
        <.stat_row label="Close Calls" value={@hero.close_calls} color="text-red-400" />
      </div>
    </div>

    <!-- Resource Usage -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-purple-400 mb-3">🧪 Resource Usage</h3>
      <div class="grid grid-cols-2 gap-3 text-sm">
        <.stat_row label="Healing Potions Used" value={@hero.potions_used_healing} />
        <.stat_row label="Damage Potions Used" value={@hero.potions_used_damage} />
        <.stat_row label="Potions Found" value={@hero.potions_found} />
        <.stat_row label="Potions Declined" value={@hero.potions_declined} />
      </div>
    </div>

    <!-- Monster Kills -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-yellow-400 mb-3">💀 Monsters Slain</h3>
      <div class="text-sm space-y-1">
        <%= for {monster, count} <- sort_kills(@hero.monsters_killed_by_type) do %>
          <div class="flex justify-between">
            <span class="text-gray-300"><%= monster %></span>
            <span class="text-yellow-300"><%= count %></span>
          </div>
        <% end %>
      </div>
    </div>
  </div>
  """
end
```

### Tab 2: Lifetime Stats

```heex
def lifetime_stats(assigns) do
  ~H"""
  <div class="space-y-6">
    <!-- Overview -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-cyan-400 mb-3">🌟 Lifetime Overview</h3>
      <div class="grid grid-cols-2 gap-3 text-sm">
        <.stat_row label="Games Played" value={@lifetime.total_games_played} />
        <.stat_row label="Deaths" value={@lifetime.total_deaths} />
        <.stat_row label="Total Damage Dealt" value={format_large(@lifetime.lifetime_damage_dealt)} />
        <.stat_row label="Total Healing Done" value={format_large(@lifetime.lifetime_healing_done)} />
        <.stat_row label="Total Kills" value={@lifetime.lifetime_kills} />
        <.stat_row label="Bosses Defeated" value={@lifetime.lifetime_bosses_defeated} />
      </div>
    </div>

    <!-- By Difficulty -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-orange-400 mb-3">🎯 By Difficulty</h3>
      <%= for difficulty <- [:easy, :normal, :hard] do %>
        <div class="mb-3">
          <div class="text-gray-400 mb-1"><%= difficulty |> to_string() |> String.capitalize() %></div>
          <div class="grid grid-cols-2 gap-2 text-sm pl-4">
            <.stat_row
              label="Games"
              value={Map.get(@lifetime.games_by_difficulty, difficulty, 0)}
            />
            <.stat_row
              label="Best Level"
              value={Map.get(@lifetime.highest_level_by_difficulty, difficulty, 0)}
            />
          </div>
        </div>
      <% end %>
    </div>

    <!-- Favorite Victims -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-purple-400 mb-3">🎭 Monster Statistics</h3>
      <div class="text-sm space-y-2">
        <div>
          <span class="text-gray-400">Most Killed:</span>
          <span class="text-yellow-300 ml-2"><%= @lifetime.favorite_victim %></span>
        </div>
        <div class="mt-3">
          <span class="text-gray-400 block mb-1">Lifetime Kills by Type:</span>
          <div class="space-y-1 pl-4 max-h-48 overflow-y-auto">
            <%= for {monster, count} <- sort_kills(@lifetime.lifetime_monsters_killed_by_type) |> Enum.take(20) do %>
              <div class="flex justify-between">
                <span class="text-gray-300"><%= monster %></span>
                <span class="text-yellow-300"><%= count %></span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  </div>
  """
end
```

### Tab 3: Records

```heex
def records_stats(assigns) do
  ~H"""
  <div class="space-y-4">
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-yellow-400 mb-4">🏆 Personal Records</h3>
      <div class="space-y-3">
        <.record_row
          icon="🎯"
          label="Highest Level Reached"
          value={@records.highest_level_ever}
        />
        <.record_row
          icon="💥"
          label="Biggest Hit"
          value={"#{@records.highest_damage_single_hit} damage"}
        />
        <.record_row
          icon="⏱️"
          label="Longest Survival"
          value={"#{@records.longest_survival} turns"}
        />
        <.record_row
          icon="💀"
          label="Most Kills (Single Game)"
          value={@records.most_kills_single_game}
        />
        <.record_row
          icon="⚔️"
          label="Most Damage (Single Game)"
          value={@records.most_damage_single_game}
        />
      </div>
    </div>

    <!-- Recent Games -->
    <div class="bg-black p-4 rounded">
      <h3 class="text-xl text-cyan-400 mb-3">📜 Recent Games</h3>
      <div class="space-y-2 text-sm">
        <%= for run <- @records.last_10_runs do %>
          <div class="flex justify-between items-center border-b border-gray-700 pb-2">
            <div>
              <div class="text-green-400"><%= run.hero_name %></div>
              <div class="text-gray-500 text-xs">
                <%= format_datetime(run.timestamp) %>
              </div>
            </div>
            <div class="text-right">
              <div class="text-yellow-300">Level <%= run.final_level %></div>
              <div class="text-gray-400 text-xs">
                <%= run.total_kills %> kills
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>
  """
end
```

### Helper Components

```heex
def stat_row(assigns) do
  assigns = assign_new(assigns, :color, fn -> "text-green-400" end)

  ~H"""
  <div class="flex justify-between">
    <span class="text-gray-400"><%= @label %>:</span>
    <span class={@color}><%= @value %></span>
  </div>
  """
end

def record_row(assigns) do
  ~H"""
  <div class="flex items-center justify-between border-l-4 border-yellow-500 pl-3">
    <div class="flex items-center gap-2">
      <span class="text-2xl"><%= @icon %></span>
      <span class="text-gray-300"><%= @label %></span>
    </div>
    <span class="text-yellow-300 text-lg font-bold"><%= @value %></span>
  </div>
  """
end
```

---

## Implementation Details

### Tracking Statistics During Gameplay

**In Hero module, update functions to record stats:**

```elixir
def attack(hero, monster) do
  damage = calculate_damage(hero)

  hero = hero
         |> Map.update!(:total_damage_dealt, &(&1 + damage))
         |> Map.update!(:total_attacks, &(&1 + 1))
         |> Map.update!(:highest_single_damage, &max(&1, damage))

  # ... rest of attack logic
end

def take_damage(hero, damage) do
  hero = Map.update!(hero, :total_damage_taken, &(&1 + damage))
  new_hp = max(0, hero.hp - damage)

  hero = %{hero | hp: new_hp}

  # Check for close call
  hero = if new_hp > 0 and new_hp < 10 do
    Map.update!(hero, :close_calls, &(&1 + 1))
  else
    hero
  end

  hero
end

def rest(hero) do
  heal_amount = calculate_healing(hero)

  hero
  |> Map.update!(:total_health_healed, &(&1 + heal_amount))
  |> Map.update!(:heal_from_resting, &(&1 + heal_amount))
  |> Map.update!(:total_rests, &(&1 + 1))
  |> apply_healing(heal_amount)
end

def use_potion(hero, potion, monster) do
  case potion.category do
    :healing ->
      heal = calculate_potion_healing(potion, hero)
      hero
      |> Map.update!(:total_health_healed, &(&1 + heal))
      |> Map.update!(:heal_from_potions, &(&1 + heal))
      |> Map.update!(:potions_used_healing, &(&1 + 1))
      |> apply_healing(heal)

    :damage ->
      damage = calculate_potion_damage(potion, monster)
      hero
      |> Map.update!(:potions_used_damage, &(&1 + 1))
  end
end
```

**Perfect Fight Detection:**

```elixir
# In GameState, track HP before and after fight
def handle_fight(state) do
  hp_before_fight = state.hero.hp

  # ... execute fight ...

  # If monster defeated and hero took no damage
  hero = if monster_defeated? and state.hero.hp == hp_before_fight do
    Map.update!(state.hero, :perfect_fights, &(&1 + 1))
  else
    state.hero
  end

  %{state | hero: hero}
end
```

### Saving Statistics After Game Over

```elixir
# In GameLive, when hero dies:
def handle_event("save_score", _, socket) do
  game_state = socket.assigns.game_state

  # Save to high scores (existing)
  score = Score.new(
    game_state.hero.name,
    game_state.hero.level,
    game_state.hero.total_kills,
    game_state.difficulty
  )
  ScoreRepo.add_score(score)

  # Save to lifetime stats (NEW)
  StatsRepo.record_game_completion(game_state)

  # ... rest of handler
end
```

### StatsRepo Implementation

```elixir
defmodule SuperDungeonSlaughterEx.Repos.StatsRepo do
  use GenServer

  def record_game_completion(game_state) do
    GenServer.cast(__MODULE__, {:record_game, game_state})
  end

  def handle_cast({:record_game, game_state}, state) do
    hero = game_state.hero

    # Update aggregate stats
    new_stats = state.stats
    |> Map.update!(:total_games_played, &(&1 + 1))
    |> Map.update!(:total_deaths, &(&1 + 1))
    |> Map.update!(:lifetime_damage_dealt, &(&1 + hero.total_damage_dealt))
    |> Map.update!(:lifetime_healing_done, &(&1 + hero.total_health_healed))
    |> Map.update!(:lifetime_kills, &(&1 + hero.total_kills))
    |> Map.update!(:lifetime_bosses_defeated, &(&1 + hero.bosses_defeated))

    # Update records
    new_stats = update_records(new_stats, hero)

    # Update difficulty stats
    new_stats = update_difficulty_stats(new_stats, game_state)

    # Update monster kill breakdown
    new_stats = update_monster_breakdown(new_stats, hero.monsters_killed_by_type)

    # Add to recent runs
    run_summary = create_run_summary(game_state)
    recent = [run_summary | new_stats.last_10_runs] |> Enum.take(10)
    new_stats = %{new_stats | last_10_runs: recent}

    # Save to disk
    save_stats(new_stats, state.json_path)

    {:noreply, %{state | stats: new_stats}}
  end

  defp update_records(stats, hero) do
    stats
    |> Map.update!(:highest_level_ever, &max(&1, hero.level))
    |> Map.update!(:highest_damage_single_hit, &max(&1, hero.highest_single_damage))
    |> Map.update!(:most_kills_single_game, &max(&1, hero.total_kills))
    |> Map.update!(:most_damage_single_game, &max(&1, hero.total_damage_dealt))
  end
end
```

---

## Testing Strategy

### Unit Tests

```elixir
describe "stat tracking" do
  test "attack increments total_attacks and total_damage_dealt" do
    hero = Hero.new("Test")
    {hero, _monster, damage, _msg} = Hero.attack(hero, monster)

    assert hero.total_attacks == 1
    assert hero.total_damage_dealt == damage
  end

  test "tracks highest single damage" do
    hero = Hero.new("Test")

    # Simulate multiple attacks
    {hero, _, dmg1, _} = Hero.attack(hero, monster)
    {hero, _, dmg2, _} = Hero.attack(hero, monster)

    assert hero.highest_single_damage == max(dmg1, dmg2)
  end

  test "perfect fight increments counter when no damage taken" do
    state = setup_game()
    hp_before = state.hero.hp

    state = kill_monster_without_taking_damage(state)

    assert state.hero.hp == hp_before
    assert state.hero.perfect_fights == 1
  end
end
```

### Integration Tests

```elixir
test "lifetime stats persist across games", %{conn: conn} do
  # Play first game
  {:ok, view, _} = live(conn, "/")
  play_until_death(view)

  # Check lifetime stats
  lifetime = StatsRepo.get_lifetime_stats()
  assert lifetime.total_games_played == 1

  # Play second game
  {:ok, view, _} = live(conn, "/")
  play_until_death(view)

  # Verify incremented
  lifetime = StatsRepo.get_lifetime_stats()
  assert lifetime.total_games_played == 2
end
```

---

## Future Enhancements

### Phase 2: Visualizations
- Charts for damage/healing over time
- Monster kill distribution pie chart
- Level progression graph

### Phase 3: Comparisons
- Compare current run to average
- Percentile rankings
- Improvement trends

### Phase 4: Achievements
- Badge system based on stats
- Unlock special features
- Share achievements

---

## Success Criteria

- [ ] All new stats tracked correctly during gameplay
- [ ] Lifetime stats persist across sessions
- [ ] Stats dashboard accessible via modal
- [ ] Three tabs: Current Run, Lifetime, Records
- [ ] Stats display correctly formatted
- [ ] No performance impact on gameplay
- [ ] All tests pass
- [ ] Stats saved after each game completion
- [ ] Recent games list shows last 10 runs
- [ ] Records update when broken
