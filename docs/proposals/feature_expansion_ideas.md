# Feature Expansion Ideas for Super Dungeon Slaughter EX

**Date:** 2025-11-27
**Status:** Proposals for future consideration

---

## Strategic Depth Features

### 1. Equipment System
Add weapons, armor, and accessories that drop from monsters or can be found:
- **Weapons**: Modify damage range/type (e.g., "Flaming Sword" adds fire damage)
- **Armor**: Damage reduction percentage or flat reduction
- **Accessories**: Special effects (increased potion drops, critical hit chance, vampiric healing)
- Could use the existing inventory pattern with separate equipment slots

**Implementation Notes:**
- Similar structure to potion system
- Equipment slots separate from inventory
- Drop rates similar to potions
- Stats modifications applied to hero during combat calculations

---

### 2. Monster Special Abilities
Make combat more dynamic with monster-specific abilities:
- **Poison/Burn**: Damage over time effects
- **Heal**: Some monsters restore HP mid-fight
- **Stun**: Skip player's next turn
- **Armor Break**: Reduce player's defense temporarily
- **Berserker**: Monster deals more damage when low HP
- This would make monster choice more meaningful and combat less predictable

**Implementation Notes:**
- Add `abilities` field to monster templates
- Trigger conditions (on hit, on low HP, random chance)
- Status effect tracking in GameState
- Visual indicators for active effects

---

### 3. Hero Classes/Skills
Let players choose a class at game start:
- **Warrior**: Higher HP, lower healing
- **Rogue**: Critical hit chance, dodge mechanics
- **Cleric**: Enhanced healing, can't use damage potions
- **Mage**: Can cast spells using a mana system
- Each could unlock abilities as they level up

**Implementation Notes:**
- Class selection during hero creation
- Class-specific stat modifiers
- Unlockable abilities at milestone levels
- Separate skill tree or linear progression

---

## Progression & Replayability

### 4. Persistent Unlocks/Meta-progression
Reward repeated playthroughs:
- **Achievements**: Track milestones (reach level 10, kill 100 goblins, etc.)
- **Unlock System**: Earn points to unlock new starting bonuses (extra potion slot, higher starting stats)
- **Bestiary**: Track which monsters you've encountered with stats/lore
- Store in JSON similar to the high scores system

**Implementation Notes:**
- New GenServer for achievement/unlock tracking
- JSON persistence for cross-session data
- UI panel for viewing achievements
- Point system for unlocks (based on achievements earned)

---

### 5. Dungeon Floors/Boss Encounters ⭐ SELECTED
Add structure to progression:
- Every 5-10 levels, face a **Boss Monster** with unique mechanics
- Bosses drop guaranteed rare loot
- Floor transitions with difficulty spikes
- Optional "rest areas" between floors to strategize

**Implementation Notes:**
- Boss flag in monster templates or special boss monster list
- Boss encounter triggers at specific level milestones
- Enhanced rewards (guaranteed potion drops, equipment)
- Visual distinction in UI (special boss display)
- Potential for multi-phase boss fights
- Floor transition messaging and progression markers

**Potential Boss Types:**
- **Level 10**: Goblin King - High HP, calls minions
- **Level 20**: Ancient Lich - Drains health, casts curses
- **Level 30**: Dragon Lord - Fire attacks, high damage
- **Level 50**: Demon Prince - Multi-phase fight
- **Level 75**: Void Titan - Reality-bending abilities
- **Level 100**: The Undying - Ultimate challenge

---

### 6. Challenge Modes
Beyond Easy/Normal/Hard:
- **Ironman**: Potions heal 50% less
- **Speed Run**: Bonus points for fast completion
- **Pacifist**: Can only rest, no fighting (use damage potions only)
- **Endless**: See how high you can level before death

**Implementation Notes:**
- Challenge mode selection at game start
- Mode-specific rules enforced in combat logic
- Separate leaderboards per challenge mode
- Special badges/rewards for completing challenges

---

## Resource Management

### 7. Gold/Currency System
Add economic layer:
- Monsters drop gold based on level/difficulty
- **Shop**: Appears every N levels to buy potions, equipment, stat upgrades
- **Risk/Reward**: Buy expensive items or save for later floors
- Adds strategic depth to inventory decisions

**Implementation Notes:**
- Add gold to hero state
- Gold drop calculation based on monster level
- Shop UI component (modal or dedicated view)
- Item pricing balanced against drop rates
- Shop inventory generation

---

### 8. Crafting/Alchemy
Let players create potions:
- Combine two potions to create stronger versions
- Recipe discovery system
- Trade-off: Use two slots for crafting materials vs one finished potion

**Implementation Notes:**
- Recipe system (combinations that produce results)
- Crafting UI for selecting potion combinations
- Discovery tracking (unlocked recipes)
- Material/ingredient concept

---

## UI/Quality of Life

### 9. Combat Log Filters
With the extensive history system already in place:
- Filter by event type (only show damage, only show items)
- Search combat log
- Export full combat log for analysis

**Implementation Notes:**
- Filter state in LiveView assigns
- Client-side filtering for performance
- Export to JSON or text format
- Search highlighting

---

### 10. Stat Tracking Dashboard ⭐ SELECTED
Expand the existing stats system:
- **Lifetime Stats**: Total across all playthroughs
- **Graphs**: Damage trends, survival rate by difficulty
- **Records**: Highest damage dealt, longest streak, etc.
- **Per-run Analytics**: Damage per turn average, potions used efficiently

**Implementation Notes:**
- Separate GenServer for lifetime stats (persistent JSON)
- Enhanced stats tracking in Hero module
- New UI component for stats dashboard
- Chart library integration (optional)
- Stats categories:
  - Combat: Total damage, highest hit, critical hits, average damage
  - Survival: Games played, deaths, highest level, longest run
  - Resources: Potions used, potions found, gold earned (if implemented)
  - Monsters: Total kills by type, boss kills, rare monster encounters
  - Efficiency: Damage per rest ratio, potion efficiency, perfect fights (no damage taken)

**Potential Stats to Track:**
```elixir
# Per-run stats (already tracked):
- total_damage_dealt
- total_health_healed
- monsters_killed_by_type
- total_kills
- final_level

# Additional per-run stats:
- highest_single_damage
- perfect_fights (no damage taken)
- potions_used_count
- potions_found_count
- bosses_defeated
- total_rests
- close_calls (survived with HP < 5)

# Lifetime stats (new):
- total_games_played
- total_deaths
- highest_level_ever
- total_lifetime_damage
- total_lifetime_healing
- total_lifetime_kills
- favorite_monster_to_kill (most killed)
- nemesis_monster (most deaths to)
```

---

## Social/Competition

### 11. Daily Challenge
Seeded runs for competition:
- Same monster sequence for all players each day
- Leaderboard specific to daily challenge
- Time-limited (24 hours)

**Implementation Notes:**
- Seed-based monster generation
- Daily seed rotation
- Separate leaderboard for daily challenges
- Challenge history tracking

---

### 12. Spectator Mode
Watch other players' runs (if you add multiplayer later):
- Real-time viewing
- Replay saved high-score runs
- Learn strategies from top players

**Implementation Notes:**
- Combat log serialization
- Replay system from saved game events
- Playback controls (speed, pause, skip)

---

## Priority Recommendations

### High Priority (Best ROI)
1. **Boss Encounters/Floor Transitions** (#5) - Adds structure and memorable moments
2. **Stat Tracking Dashboard** (#10) - Enhances existing system, increases engagement
3. **Equipment System** (#1) - Natural progression, meaningful choices

### Medium Priority
4. **Monster Special Abilities** (#2) - Makes combat more interesting
5. **Persistent Unlocks** (#4) - Increases replayability significantly
6. **Challenge Modes** (#6) - Extends gameplay variety

### Lower Priority (Nice to Have)
7. **Gold/Currency System** (#7) - Adds economy layer
8. **Hero Classes** (#3) - Major system, high implementation cost
9. **Combat Log Filters** (#9) - QoL improvement
10. **Crafting/Alchemy** (#8) - Complex system, may over-complicate

### Future Considerations
11. **Daily Challenge** (#11) - Requires player base
12. **Spectator Mode** (#12) - Requires replay infrastructure

---

## Implementation Strategy

For each feature, follow this pattern:
1. **Design Phase**: Document mechanics, data structures, edge cases
2. **Data Layer**: Update models and persistence (if needed)
3. **Game Logic**: Implement core functionality
4. **UI Layer**: Add components and views
5. **Testing**: Unit tests, integration tests, manual testing
6. **Balance**: Tune numbers based on playtesting

---

## Notes

- These proposals complement the existing game architecture
- Most can be implemented independently without conflicts
- Features #5 and #10 selected for initial implementation
- All ideas maintain the retro dungeon crawler aesthetic
- Focus on strategic depth without over-complication
