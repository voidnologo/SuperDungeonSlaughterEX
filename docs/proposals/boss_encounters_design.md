# Boss Encounters & Floor Transitions - Design Document

**Date:** 2025-11-27
**Status:** Design phase
**Priority:** High

---

## Overview

Add structured progression to the game with boss encounters at milestone levels and floor transition mechanics. This feature provides memorable moments, breaks up the grinding loop, and gives players concrete goals to work towards.

---

## Goals

1. **Memorable Moments**: Create exciting boss fights that feel distinct from regular combat
2. **Progression Structure**: Give players clear milestones and sense of advancement
3. **Enhanced Rewards**: Bosses guarantee better loot to incentivize engagement
4. **Scalable Design**: System works from level 10 through level 100+
5. **Maintain Balance**: Bosses challenging but not impossible

---

## Core Mechanics

### Boss Encounter Triggers

**Option A: Fixed Level Intervals**
- Boss appears every 10 levels (10, 20, 30, 40, etc.)
- Predictable, easy to design around
- Players can prepare for upcoming boss

**Option B: Floor-Based System**
- Each "floor" is 5-10 levels
- Boss at end of each floor
- Floor transition after boss defeat
- More thematic (dungeon exploration feel)

**Recommendation: Option B (Floor-based)**
- More immersive narrative structure
- Allows for floor-specific themes
- Natural place for rest/shop mechanics (future)

### Floor Structure

```
Floor 1: Levels 1-10   → Boss: Goblin King
Floor 2: Levels 11-20  → Boss: Ancient Lich
Floor 3: Levels 21-30  → Boss: Dragon Lord
Floor 4: Levels 31-40  → Boss: Vampire Count
Floor 5: Levels 41-50  → Boss: Demon Prince
Floor 6: Levels 51-60  → Boss: Frost Titan
Floor 7: Levels 61-70  → Boss: Shadow Archon
Floor 8: Levels 71-80  → Boss: Void Titan
Floor 9: Levels 81-90  → Boss: Reality Eater
Floor 10: Levels 91-100 → Boss: The Undying
```

### Boss Characteristics

**Enhanced Stats:**
- HP: 3-4x normal monster at that level
- Damage: 1.5-2x normal monster
- No Gaussian randomization (fixed, predictable stats)

**Special Mechanics (Future Enhancement):**
- Multi-phase fights (HP thresholds trigger changes)
- Special abilities (heal, status effects, etc.)
- Unique attack patterns

**For Initial Implementation:**
- Just enhanced stats + special visual treatment
- Can add mechanics later without refactoring

### Boss Rewards

**Guaranteed Drops:**
- Always drop 1 Major potion (player chooses healing or damage)
- Bonus: 50% chance for second potion (random quality/type)
- Future: Guaranteed equipment/gold

**Victory Bonuses:**
- Floor completion message
- Bonus HP heal to full (celebrating victory)
- Achievement tracking (bosses defeated)

---

## Data Model Changes

### Monster Template Extensions

**Option 1: Add boss flag to existing templates**
```json
{
  "Goblin King": {
    "min_level": 10,
    "max_level": 10,
    "avg_hp": 150,
    "hp_sigma": 0,
    "damage_base": 12,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 1
  }
}
```

**Option 2: Separate boss file**
```json
// priv/data/bosses.json
{
  "bosses": [
    {
      "name": "Goblin King",
      "floor": 1,
      "level": 10,
      "hp": 150,
      "damage": 12,
      "description": "The tyrannical ruler of the goblin hordes"
    }
  ]
}
```

**Recommendation: Option 1**
- Reuses existing MonsterRepo infrastructure
- Easier to maintain (all monsters in one place)
- Boss is just a special monster type

### GameState Extensions

Add floor tracking:
```elixir
defmodule SuperDungeonSlaughterEx.Game.GameState do
  @type t :: %__MODULE__{
    hero: Hero.t(),
    monster: Monster.t(),
    history: [HistoryEntry.t()],
    game_over: boolean(),
    current_floor: pos_integer(),  # NEW
    pending_boss_reward: boolean() # NEW
  }
end
```

### Hero Extensions

Track boss victories:
```elixir
defmodule SuperDungeonSlaughterEx.Game.Hero do
  @type t :: %__MODULE__{
    # ... existing fields ...
    bosses_defeated: non_neg_integer(),
    current_floor: pos_integer()
  }
end
```

---

## Implementation Details

### Monster Module Changes

Add boss detection:
```elixir
# lib/super_dungeon_slaughter_ex/game/monster.ex

def is_boss?(%Monster{} = monster) do
  # Check if monster has boss flag in original template
  # Could store this in monster struct
  Map.get(monster, :is_boss, false)
end

def boss_display_name(monster) do
  "⚔️ BOSS: #{monster.name} ⚔️"
end
```

### MonsterRepo Changes

Add boss spawning:
```elixir
# lib/super_dungeon_slaughter_ex/repos/monster_repo.ex

def get_boss_for_level(level) do
  GenServer.call(__MODULE__, {:get_boss, level})
end

def handle_call({:get_boss, level}, _from, state) do
  # Find boss monster for this level
  boss = state.templates
         |> Enum.find(fn {_name, template} ->
            Map.get(template, "is_boss", false) &&
            template["min_level"] == level
         end)

  case boss do
    {_name, template} ->
      monster = Monster.from_template(template)
      {:reply, {:ok, monster}, state}
    nil ->
      {:reply, {:error, :no_boss_found}, state}
  end
end
```

### GameState Changes

Boss encounter logic:
```elixir
# lib/super_dungeon_slaughter_ex/game/game_state.ex

defp should_spawn_boss?(hero_level) do
  # Boss every 10 levels
  rem(hero_level, 10) == 0 && hero_level > 0
end

defp spawn_next_monster(state) do
  hero_level = state.hero.level

  if should_spawn_boss?(hero_level) do
    case MonsterRepo.get_boss_for_level(hero_level) do
      {:ok, boss} ->
        floor = div(hero_level, 10)
        state
        |> Map.put(:monster, boss)
        |> Map.put(:current_floor, floor)
        |> add_boss_announcement(boss, floor)

      {:error, _} ->
        # Fallback to regular monster
        spawn_regular_monster(state)
    end
  else
    spawn_regular_monster(state)
  end
end

defp add_boss_announcement(state, boss, floor) do
  entry = HistoryEntry.separator("=== FLOOR #{floor} BOSS ===")
  boss_entry = HistoryEntry.new(
    "💀 #{boss.name} blocks your path! 💀",
    :boss_encounter,
    "🗡️",
    "text-red-500"
  )

  state
  |> add_to_history(entry)
  |> add_to_history(boss_entry)
end

defp handle_boss_defeat(state) do
  floor = state.current_floor

  state
  |> add_to_history(HistoryEntry.new(
      "⭐ You defeated the Floor #{floor} Boss! ⭐",
      :boss_victory,
      "🏆",
      "text-yellow-300"
    ))
  |> Map.put(:pending_boss_reward, true)
  |> fully_heal_hero()
end

defp fully_heal_hero(state) do
  healed_hero = %{state.hero | hp: state.hero.hp_max}
  %{state | hero: healed_hero}
end
```

---

## UI Changes

### Boss Visual Distinction

**Monster Stats Panel Enhancement:**
```heex
<!-- lib/super_dungeon_slaughter_ex_web/components/game_components.ex -->

<div class={[
  "border-2 p-4 rounded bg-gray-800",
  if(@monster.is_boss, do: "border-red-500 animate-pulse", else: "border-orange-500")
]}>
  <h2 class={[
    "text-xl font-bold mb-3",
    if(@monster.is_boss, do: "text-red-400 text-2xl", else: "text-orange-400")
  ]}>
    <%= if @monster.is_boss do %>
      ⚔️ BOSS FIGHT ⚔️
    <% else %>
      Monster Stats
    <% end %>
  </h2>

  <!-- Rest of stats display -->
</div>
```

**Floor Indicator:**
```heex
<!-- Add to hero stats panel -->
<div class="flex justify-between">
  <span>Floor:</span>
  <span class="text-cyan-400"><%= @game_state.current_floor %></span>
</div>
```

### Boss Reward Modal

New modal for boss victory rewards:
```heex
def boss_reward_modal(assigns) do
  ~H"""
  <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
    <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-8 max-w-md">
      <h2 class="text-3xl font-bold text-yellow-400 text-center mb-4">
        🏆 BOSS DEFEATED! 🏆
      </h2>

      <p class="text-green-400 text-center mb-6">
        You have conquered Floor <%= @current_floor %>!
        Your wounds heal as you rest.
      </p>

      <div class="bg-black p-4 rounded mb-6">
        <h3 class="text-xl text-purple-400 mb-3">Choose Your Reward:</h3>
        <div class="flex gap-4 justify-center">
          <button
            phx-click="claim_boss_reward"
            phx-value-type="healing"
            class="px-6 py-3 bg-green-600 hover:bg-green-700 rounded"
          >
            🏺 Major Healing Potion
          </button>
          <button
            phx-click="claim_boss_reward"
            phx-value-type="damage"
            class="px-6 py-3 bg-red-600 hover:bg-red-700 rounded"
          >
            🏺 Major Damage Potion
          </button>
        </div>
      </div>

      <p class="text-gray-400 text-sm text-center">
        The path ahead grows darker...
      </p>
    </div>
  </div>
  """
end
```

### Combat History Enhancements

New history entry types:
```elixir
# Boss encounter
HistoryEntry.new("💀 BOSS APPEARED", :boss_encounter, "⚔️", "text-red-500")

# Boss victory
HistoryEntry.new("🏆 BOSS DEFEATED", :boss_victory, "👑", "text-yellow-300")

# Floor transition
HistoryEntry.new("📍 Entering Floor 2", :floor_transition, "🚪", "text-cyan-400")
```

---

## Boss Definitions

### Initial Boss List (10 bosses, levels 10-100)

```json
{
  "Goblin King": {
    "min_level": 10,
    "max_level": 10,
    "avg_hp": 200,
    "hp_sigma": 0,
    "damage_base": 15,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 1
  },
  "Ancient Lich": {
    "min_level": 20,
    "max_level": 20,
    "avg_hp": 650,
    "hp_sigma": 0,
    "damage_base": 45,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 2
  },
  "Dragon Lord": {
    "min_level": 30,
    "max_level": 30,
    "avg_hp": 1800,
    "hp_sigma": 0,
    "damage_base": 110,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 3
  },
  "Vampire Count": {
    "min_level": 40,
    "max_level": 40,
    "avg_hp": 4200,
    "hp_sigma": 0,
    "damage_base": 230,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 4
  },
  "Demon Prince": {
    "min_level": 50,
    "max_level": 50,
    "avg_hp": 8500,
    "hp_sigma": 0,
    "damage_base": 450,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 5
  },
  "Frost Titan": {
    "min_level": 60,
    "max_level": 60,
    "avg_hp": 15000,
    "hp_sigma": 0,
    "damage_base": 800,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 6
  },
  "Shadow Archon": {
    "min_level": 70,
    "max_level": 70,
    "avg_hp": 24000,
    "hp_sigma": 0,
    "damage_base": 1300,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 7
  },
  "Void Titan": {
    "min_level": 80,
    "max_level": 80,
    "avg_hp": 38000,
    "hp_sigma": 0,
    "damage_base": 2000,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 8
  },
  "Reality Eater": {
    "min_level": 90,
    "max_level": 90,
    "avg_hp": 58000,
    "hp_sigma": 0,
    "damage_base": 3000,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 9
  },
  "The Undying": {
    "min_level": 100,
    "max_level": 100,
    "avg_hp": 85000,
    "hp_sigma": 0,
    "damage_base": 4500,
    "damage_sigma": 0,
    "is_boss": true,
    "floor": 10
  }
}
```

**Note:** Stats calculated to require 5-8 hits to kill with proper potion management, while threatening enough to kill player in 8-12 hits.

---

## Testing Strategy

### Unit Tests

```elixir
# test/super_dungeon_slaughter_ex/game/game_state_test.exs

describe "boss encounters" do
  test "spawns boss at level 10" do
    state = GameState.new("Hero")
    state = level_up_to(state, 10)

    assert state.monster.is_boss == true
    assert state.current_floor == 1
  end

  test "boss defeat heals hero to full" do
    state = setup_boss_fight(10)
    state = %{state | hero: %{state.hero | hp: 5}}  # Low HP

    state = defeat_current_boss(state)

    assert state.hero.hp == state.hero.hp_max
  end

  test "boss defeat sets pending reward flag" do
    state = setup_boss_fight(10)
    state = defeat_current_boss(state)

    assert state.pending_boss_reward == true
  end

  test "regular monsters spawn between bosses" do
    state = GameState.new("Hero")
    state = level_up_to(state, 15)

    refute state.monster.is_boss
  end
end
```

### Integration Tests

```elixir
# test/super_dungeon_slaughter_ex_web/live/game_live_test.exs

test "boss reward modal appears after boss defeat", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/")

  # Level up to 10 and defeat boss
  html = level_and_defeat_boss(view, 10)

  assert html =~ "BOSS DEFEATED"
  assert html =~ "Choose Your Reward"
  assert html =~ "Major Healing Potion"
  assert html =~ "Major Damage Potion"
end

test "claiming boss reward adds potion to inventory", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/")

  level_and_defeat_boss(view, 10)

  html = view
         |> element("button", "Major Healing Potion")
         |> render_click()

  assert html =~ "Major Healing Potion"  # In inventory
  refute html =~ "Choose Your Reward"    # Modal closed
end
```

### Manual Testing Checklist

- [ ] Boss appears at level 10, 20, 30, etc.
- [ ] Boss has distinct visual treatment (red border, pulse animation)
- [ ] Boss has significantly more HP than regular monsters
- [ ] Boss victory fully heals hero
- [ ] Boss reward modal appears after victory
- [ ] Can choose healing or damage potion reward
- [ ] Reward potion added to inventory (or modal for full inventory)
- [ ] Floor number displays correctly in stats panel
- [ ] Combat history shows boss encounter messages
- [ ] Can defeat multiple bosses in one run
- [ ] Boss stats scale appropriately at higher levels

---

## Future Enhancements

### Phase 2: Boss Mechanics
- Multi-phase fights (boss transforms at 50% HP)
- Boss-specific abilities
- Unique attack patterns
- Status effects (poison, stun, etc.)

### Phase 3: Floor Themes
- Visual themes per floor (color schemes, icons)
- Floor-specific monster families
- Environmental effects

### Phase 4: Rest Areas
- Safe zones between floors
- Shop access
- Stat upgrades
- Strategic choices before boss

---

## Implementation Phases

### Phase 1: Core Boss System (This PR)
1. Add boss templates to monsters.json
2. Update Monster module with is_boss flag
3. Add floor tracking to GameState and Hero
4. Implement boss spawning logic
5. Add boss defeat rewards
6. Create boss reward modal UI
7. Update combat history for boss events
8. Write tests

### Phase 2: Polish & Balance
1. Tune boss stats based on playtesting
2. Add animations for boss encounters
3. Improve visual distinction
4. Add sound effects (future)
5. Achievement tracking for bosses

### Phase 3: Advanced Features
1. Boss abilities
2. Multi-phase fights
3. Floor themes
4. Rest areas

---

## Success Criteria

- [ ] Boss spawns every 10 levels
- [ ] Boss has 3-4x HP of regular monsters
- [ ] Boss victory heals hero to full
- [ ] Boss always drops Major potion (player choice)
- [ ] UI clearly distinguishes bosses from regular monsters
- [ ] Floor number tracks correctly
- [ ] All tests pass
- [ ] No regression in existing functionality
- [ ] Boss encounters feel exciting and rewarding
