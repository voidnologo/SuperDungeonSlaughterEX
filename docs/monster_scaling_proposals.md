# Monster Scaling Proposals

**Date:** 2025-11-26
**Purpose:** Design document for scaling monster difficulty from levels 1-100+ to maintain challenge as player progresses

## Current System Analysis

### Monster Definition System
- **Location:** `priv/data/monsters.json`
- **Count:** 11 unique monster types
- **Highest max_level:** 30 (Greater Dragon)
- **Stats Model:** Gaussian distributions for HP and damage

**Monster Structure:**
```json
{
  "MonsterName": {
    "min_level": 0,
    "max_level": 5,
    "avg_hp": 5,
    "hp_sigma": 0.5,
    "damage_base": 2,
    "damage_sigma": 1
  }
}
```

### Hero Scaling Mechanics
Located in `lib/super_dungeon_slaughter_ex/game/hero.ex`:

```elixir
# Level up occurs after N kills at level N
# Stats scale multiplicatively:
damage_min/max: +10% per level
heal_min/max: +15% per level
hp_max: +(current_level + 1) per level
```

**Power Progression:**
- Level 10: ~3.6x damage, ~4.0x healing vs level 1
- Level 30: ~17x damage, ~66x healing vs level 1
- Level 100: ~13,780x damage, ~1,174,313x healing vs level 1

### Current Problem
With inventory and potions, players can:
- Outlast max monster damage at high levels
- One-shot kill monsters once level exceeds monster max_level
- Combat becomes trivial after level 30

### Design Goals
1. Players kill monsters in 2-8 hits on average (some outliers allowed)
2. Monsters remain threatening and can damage/kill players
3. Progressive unlocking of new monster types
4. Combat stays engaging through level 100
5. Players can heal through fights with potions

---

## Option 1: Expanded Monster List

### Overview
Create 80-100 unique monster types covering the full level range (0-100+).

### Implementation Details

**Content Creation:**
- Expand `priv/data/monsters.json` with ~90 new entries
- No code changes required to core systems
- Uses existing MonsterRepo level indexing and spawning

**Monster Tier Structure:**
- **Tier 1 (Levels 0-10):** Basic creatures - 15 monsters
  - Goblins, Kobolds, Rats, Slimes, Spiders, Bats, etc.

- **Tier 2 (Levels 10-20):** Intermediate threats - 15 monsters
  - Orcs, Hobgoblins, Bandits, Wolves, Bears, Skeletons

- **Tier 3 (Levels 20-35):** Magical creatures - 20 monsters
  - Elementals, Wraiths, Specters, Gargoyles, Cultists, Warlocks

- **Tier 4 (Levels 35-50):** Elite monsters - 20 monsters
  - Golems, Wyverns, Chimeras, Minotaurs, Vampires, Liches

- **Tier 5 (Levels 50-70):** Legendary beasts - 15 monsters
  - Dragons, Demons, Hydras, Phoenixes, Titans, Ancient Elementals

- **Tier 6 (Levels 70-100):** Ancient/Cosmic horrors - 15 monsters
  - Archdemons, Elder Things, Void Creatures, Primordial Beasts, Cosmic Horrors

**Balancing Formula:**

To maintain 2-8 hit kills, monster stats must scale with player power:

```
Hero damage at level N:
  damage_avg = (starting_damage_avg) * (1.1^N)
  starting_damage_avg = (damage_min + damage_max) / 2 = 1.5

Hero HP at level N:
  hp_max = starting_hp + sum(i=1 to N-1)(i + 1)
  hp_max = 10 + (N*(N+1)/2)

Target: Kill monster in 2-8 hits (avg 5 hits)
Monster HP = hero_damage_avg * 5 (with sigma for variation)

Target: Monster kills player in 6-12 hits (avg 8 hits)
Monster damage = hero_hp_max / 8 (with sigma for variation)
```

**Exact Formulas for JSON Generation:**

For a monster at level range [min_level, max_level]:
```python
mid_level = (min_level + max_level) / 2

# Hero stats at mid_level
hero_damage_avg = 1.5 * (1.1 ** mid_level)
hero_hp_max = 10 + (mid_level * (mid_level + 1) / 2)

# Monster stats (targeting 5-hit kill, 8-hit survival)
avg_hp = hero_damage_avg * 5
hp_sigma = hero_damage_avg * 1.5  # ~30% variation

damage_base = hero_hp_max / 8
damage_sigma = damage_base * 0.4  # ~40% variation
```

**Example Monsters:**

```json
{
  "Goblin": {
    "min_level": 0,
    "max_level": 8,
    "avg_hp": 7.5,
    "hp_sigma": 2.25,
    "damage_base": 1.5,
    "damage_sigma": 0.6
  },
  "Corrupted Knight": {
    "min_level": 45,
    "max_level": 55,
    "avg_hp": 390,
    "hp_sigma": 117,
    "damage_base": 163,
    "damage_sigma": 65
  },
  "Void Horror": {
    "min_level": 90,
    "max_level": 100,
    "avg_hp": 65000,
    "hp_sigma": 19500,
    "damage_base": 6400,
    "damage_sigma": 2560
  }
}
```

### Pros
- **Low code complexity** - uses existing system without modifications
- **Rich variety and flavor** - unique monsters throughout progression
- **Easy to balance** - tweak individual JSON values
- **No runtime calculations** - simple lookups
- **Clear progression** - themed tiers create narrative arc
- **Allows outliers** - can create special boss-like monsters (e.g., "The Undying")
- **Difficulty spikes possible** - place harder monsters at key levels

### Cons
- **High content creation effort** - requires designing ~80-100 monsters
- **Manual balancing** - each monster needs individual tuning
- **Maintenance burden** - updates to hero scaling require re-balancing all monsters
- **May feel repetitive** - similar stat patterns at high levels despite different names
- **File size** - large JSON file (~400-500 lines)

### Implementation Steps
1. Generate balanced monster list using formulas
2. Create creative names for each tier
3. Add variety with special monsters (high HP, high damage, balanced, etc.)
4. Test balance at key levels (10, 25, 50, 75, 100)
5. Adjust outliers as needed

---

## Option 2: Dynamic Stat Scaling

### Overview
Keep ~20-30 monster archetypes, scale their stats dynamically based on player level at spawn time.

### Implementation Details

**Code Changes Required:**

**1. Update Monster Template Schema** (`priv/data/monsters.json`):
```json
{
  "Goblin": {
    "base_level": 5,        // NEW: reference level for base stats
    "min_level": 0,
    "max_level": 100,       // Can now appear at any level
    "base_hp": 7.5,         // Base stats at base_level
    "hp_sigma_ratio": 0.3,  // Sigma as ratio of HP
    "base_damage": 1.5,
    "damage_sigma_ratio": 0.4
  }
}
```

**2. Modify MonsterRepo** (`lib/super_dungeon_slaughter_ex/repos/monster_repo.ex`):
```elixir
# Pass player level to monster creation
def get_monster_for_level(level) do
  GenServer.call(__MODULE__, {:get_monster, level})
end

def handle_call({:get_monster, level}, _from, state) do
  available = Map.get(state.level_index, level, [])

  if available == [] do
    # Fallback to closest level
    available = find_fallback_monsters(level, state.level_index)
  end

  name = Enum.random(available)
  template = Map.get(state.templates, name)

  # NEW: Pass player level to monster creation
  monster = Monster.from_template(template, level)
  {:reply, monster, state}
end
```

**3. Update Monster Creation** (`lib/super_dungeon_slaughter_ex/game/monster.ex`):
```elixir
def from_template(template, player_level) do
  # Calculate scaling multiplier based on level difference
  level_diff = player_level - template.base_level
  scale = :math.pow(1.1, level_diff)  # Match hero 10% scaling

  # Scale base stats
  scaled_avg_hp = template.base_hp * scale
  scaled_damage = template.base_damage * scale

  # Calculate sigma from scaled stats
  hp_sigma = scaled_avg_hp * template.hp_sigma_ratio
  damage_sigma = scaled_damage * template.damage_sigma_ratio

  # Generate stats with Gaussian distribution
  hp = :rand.normal(scaled_avg_hp, hp_sigma)
  hp = max(1, round(hp))

  # Build monster with descriptors
  hp_descriptor = get_hp_descriptor(hp, scaled_avg_hp, hp_sigma)
  damage_descriptor = get_damage_descriptor(scaled_damage, damage_sigma)

  display_name = "#{hp_descriptor} #{damage_descriptor} #{template.name}"

  %Monster{
    name: template.name,
    display_name: display_name,
    hp: hp,
    hp_max: hp,
    damage_base: scaled_damage,
    damage_sigma: damage_sigma
  }
end
```

**4. Update GameState** (`lib/super_dungeon_slaughter_ex/game/game_state.ex`):
```elixir
# Ensure player level is passed during monster spawning
def new do
  hero = Hero.new()
  monster = MonsterRepo.get_monster_for_level(hero.level)
  # ... rest of initialization
end

defp handle_monster_death(state) do
  new_monster = MonsterRepo.get_monster_for_level(state.hero.level)
  # ... rest of handling
end
```

**Monster Tier Examples:**
```json
{
  "Goblin": { "base_level": 3, "min_level": 0, "max_level": 25 },
  "Orc": { "base_level": 10, "min_level": 5, "max_level": 40 },
  "Dragon": { "base_level": 50, "min_level": 30, "max_level": 100 },
  "Void Horror": { "base_level": 85, "min_level": 70, "max_level": 200 }
}
```

### Pros
- **Low content creation effort** - only ~20-30 monster types needed
- **Automatic balancing** - scales with hero power
- **Future-proof** - works for any level cap (100, 200, unlimited)
- **Easy global tuning** - adjust scaling multiplier to change overall difficulty
- **Monsters stay relevant** - Goblins remain threatening when scaled

### Cons
- **Less variety** - fewer unique monster names/types
- **Thematic awkwardness** - "Level 80 Goblin" feels strange narratively
- **Code complexity** - requires changes to 3 core modules
- **Harder to create unique challenges** - all monsters follow same scaling curve
- **Testing burden** - must verify scaling at all level ranges
- **Descriptor system complexity** - need to handle scaled sigma values correctly

### Implementation Steps
1. Modify monster template schema in JSON
2. Update MonsterRepo to pass player level
3. Implement scaling logic in Monster.from_template/2
4. Update GameState to use new API
5. Test balance at levels 1, 10, 25, 50, 75, 100
6. Tune scaling multiplier and base stats

---

## Option 3: Hybrid Approach

### Overview
Combine both approaches: Expand monster list to ~30-40 types, each covering a 10-20 level range with dynamic scaling within that range.

### Implementation Details

**Monster Structure:**
```json
{
  "Goblin": {
    "base_level": 3,       // Reference point for stats
    "min_level": 0,
    "max_level": 15,       // Phased out after level 15
    "base_hp": 7.5,
    "hp_sigma_ratio": 0.3,
    "base_damage": 1.5,
    "damage_sigma_ratio": 0.4
  },
  "Goblin Chieftain": {
    "base_level": 18,
    "min_level": 12,
    "max_level": 28,       // Upgraded version at higher levels
    "base_hp": 95,
    "hp_sigma_ratio": 0.3,
    "base_damage": 14,
    "damage_sigma_ratio": 0.4
  },
  "Ancient Dragon": {
    "base_level": 85,
    "min_level": 70,
    "max_level": 100,
    "base_hp": 45000,
    "hp_sigma_ratio": 0.3,
    "base_damage": 5200,
    "damage_sigma_ratio": 0.4
  }
}
```

**Scaling Logic:**
```elixir
def from_template(template, player_level) do
  # Clamp player_level to monster's valid range
  clamped_level = max(template.min_level, min(player_level, template.max_level - 1))

  # Scale within the monster's range
  level_diff = clamped_level - template.base_level
  scale = :math.pow(1.1, level_diff)

  # Apply scaling
  scaled_avg_hp = template.base_hp * scale
  scaled_damage = template.base_damage * scale
  # ... rest of monster creation
end
```

**Progression Example:**
```
Level 1-15:   Goblin (scales from weak to moderate)
Level 12-28:  Goblin Chieftain (overlaps, stronger variant)
Level 25-45:  Orc Warlord
Level 40-65:  Lesser Dragon
Level 60-85:  Greater Dragon
Level 80-100: Ancient Dragon
```

Players see:
- Natural progression (new monsters appear, old ones disappear)
- Smooth difficulty curve (scaling within each monster's range)
- Thematic consistency (Goblin family → Orc family → Dragon family)
- Some variety (6-7 monster types available at any given level)

### Pros
- **Moderate content creation** - ~30-40 monsters needed (vs 80-100)
- **Good variety** - new monsters regularly, not too repetitive
- **Natural progression** - clear tier transitions
- **Automatic balancing** - scales within each tier
- **Thematic sense** - monsters phase out when outleveled
- **Best effort/reward ratio** - balances work vs variety

### Cons
- **Requires both approaches** - JSON expansion AND code changes
- **More complex than Option 1** - harder to understand and maintain
- **Medium code complexity** - requires module updates like Option 2
- **Balancing complexity** - must tune both base stats AND scaling
- **Overlap tuning** - need to carefully design level range overlaps

### Implementation Steps
1. Design monster tiers with ~5 monsters per tier
2. Implement scaling logic (same as Option 2)
3. Set level ranges with 5-10 level overlaps between tiers
4. Balance base stats for each monster
5. Test transitions between tiers
6. Adjust scaling and ranges as needed

---

## Comparison Matrix

| Criterion | Option 1: Expanded List | Option 2: Dynamic Scaling | Option 3: Hybrid |
|-----------|------------------------|---------------------------|------------------|
| **Content Creation** | High (~90 monsters) | Low (~20 monsters) | Medium (~35 monsters) |
| **Code Changes** | None | High (3 modules) | High (3 modules) |
| **Variety** | Excellent | Poor | Good |
| **Balancing Effort** | High (manual each) | Low (automatic) | Medium (semi-automatic) |
| **Theme/Narrative** | Best | Weakest | Good |
| **Future-proof** | No (hard-coded to 100) | Yes (works to ∞) | Yes (works to ∞) |
| **Maintenance** | Hard (re-balance all) | Easy (tune multiplier) | Medium |
| **Testing Burden** | Medium | High | High |
| **Difficulty Spikes** | Easy | Hard | Medium |
| **Implementation Time** | Medium | Medium | High |

---

## Recommendation

**Primary: Option 1 (Expanded Monster List)**

Reasons:
1. You indicated preference for lower impact (no code changes)
2. Fits your stated goal of "expanding the monster list"
3. Provides rich variety and flavor
4. Easier to create special monsters (The Undying, boss variants)
5. Balancing formulas can automate most of the work

**Secondary: Option 3 (Hybrid)**

If willing to invest in code changes, this provides the best long-term solution with moderate effort.

---

## Next Steps

### For Option 1 Implementation:
1. Generate balanced monster list using provided formulas
2. Create themed tiers with creative names
3. Add variety: 80% balanced, 10% high-HP tanks, 10% high-damage glass cannons
4. Include special monsters at milestone levels (25, 50, 75, 100)
5. Test at key levels and adjust

### For Option 2 or 3 Implementation:
1. Update monster.json schema
2. Modify MonsterRepo.get_monster_for_level/1
3. Implement Monster.from_template/2 with scaling
4. Update GameState monster spawning
5. Create ~20-40 monster types with level ranges
6. Test scaling across full level range
7. Tune scaling multiplier for desired difficulty

---

## Balancing Tools

### Python Script for Generating Balanced Stats

```python
import math

def hero_damage_at_level(level):
    """Calculate average hero damage at given level."""
    starting_avg = 1.5  # (0 + 3) / 2
    return starting_avg * math.pow(1.1, level)

def hero_hp_at_level(level):
    """Calculate hero max HP at given level."""
    base_hp = 10
    # Sum of (i+1) from i=1 to level-1
    hp_gains = (level * (level + 1)) / 2
    return base_hp + hp_gains

def generate_monster_stats(min_level, max_level, target_hits=5, threat_hits=8):
    """
    Generate balanced monster stats for a level range.

    Args:
        min_level: Minimum level this monster appears
        max_level: Maximum level this monster appears
        target_hits: Average hits for player to kill monster
        threat_hits: Average hits for monster to kill player

    Returns:
        Dictionary with avg_hp, hp_sigma, damage_base, damage_sigma
    """
    mid_level = (min_level + max_level) / 2

    hero_dmg = hero_damage_at_level(mid_level)
    hero_hp = hero_hp_at_level(mid_level)

    avg_hp = hero_dmg * target_hits
    hp_sigma = hero_dmg * 1.5  # 30% variation

    damage_base = hero_hp / threat_hits
    damage_sigma = damage_base * 0.4  # 40% variation

    return {
        "avg_hp": round(avg_hp, 2),
        "hp_sigma": round(hp_sigma, 2),
        "damage_base": round(damage_base, 2),
        "damage_sigma": round(damage_sigma, 2)
    }

# Example usage:
print(generate_monster_stats(0, 8))   # Goblin
print(generate_monster_stats(45, 55)) # Mid-tier monster
print(generate_monster_stats(90, 100)) # End-game monster
```

### Testing Checklist

- [ ] Level 1: Can kill starter monsters in 2-8 hits
- [ ] Level 10: Monsters still threatening, combat not trivial
- [ ] Level 25: Multiple monster types available
- [ ] Level 50: High-tier monsters appear, remain challenging
- [ ] Level 75: Combat requires strategy and healing
- [ ] Level 100: End-game monsters provide appropriate challenge
- [ ] Edge case: Test "The Undying" and other special monsters
- [ ] Verify no level gaps with zero available monsters
- [ ] Check descriptor system still produces varied names
- [ ] Confirm damage/HP outliers exist (frail, vicious, etc.)

---

## Future Considerations

### Potential Enhancements
1. **Monster abilities/traits:** Special attacks, resistances, weaknesses
2. **Elemental system:** Fire/Ice/Lightning damage types
3. **Boss monsters:** Special encounters every 10 levels
4. **Monster families:** Related monsters with shared traits
5. **Difficulty modes:** Easy/Normal/Hard with stat multipliers
6. **Adaptive difficulty:** Adjust based on player win/loss rate

### Performance Considerations
- Current system is O(1) lookup by level (level_index map)
- Expanded list adds minimal memory (~100 KB for 100 monsters)
- No performance impact on monster spawning
- Dynamic scaling adds minimal CPU (one pow operation per spawn)

### Localization
If planning translations:
- Monster names in JSON can be replaced with translation keys
- Keep descriptors ("Frail", "Vicious") separate for translation
- Display names constructed from translated components

---

## Document Version History

- **v1.0** (2025-11-26): Initial proposals for monster scaling to level 100
