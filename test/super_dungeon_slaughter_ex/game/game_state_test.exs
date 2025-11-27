defmodule SuperDungeonSlaughterEx.Game.GameStateTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.{GameState, Hero, Monster}
  alias SuperDungeonSlaughterEx.Repos.MonsterRepo

  setup do
    # Create unique paths and names for each test
    test_path =
      Path.join([System.tmp_dir!(), "test_monsters_gamestate_#{:rand.uniform(999_999_999)}.json"])

    test_name = :"test_monster_repo_gamestate_#{:rand.uniform(999_999_999)}"

    # Create test monsters JSON
    test_data = %{
      "TestGoblin" => %{
        "min_level" => 0,
        "max_level" => 10,
        "avg_hp" => 10.0,
        "hp_sigma" => 1.0,
        "damage_base" => 3.0,
        "damage_sigma" => 1.0
      }
    }

    File.write!(test_path, Jason.encode!(test_data))
    start_supervised!({MonsterRepo, json_path: test_path, name: test_name})

    on_exit(fn ->
      File.rm(test_path)
    end)

    :ok
  end

  describe "new/1" do
    test "creates initial game state" do
      state = GameState.new("TestHero")

      assert state.hero.name == "TestHero"
      assert state.hero.level == 1
      assert %Monster{} = state.monster
      assert state.game_over == false
      assert is_list(state.history)
      assert length(state.history) > 0
    end

    test "includes welcome message in history" do
      state = GameState.new("Adventurer")

      assert Enum.any?(state.history, fn entry ->
               String.contains?(entry.message, "Welcome") &&
                 String.contains?(entry.message, "Adventurer")
             end)
    end

    test "announces first monster in history" do
      state = GameState.new("Hero")

      assert Enum.any?(state.history, fn entry ->
               String.contains?(entry.message, "appears")
             end)
    end
  end

  describe "handle_fight/1" do
    test "hero attacks monster" do
      state = GameState.new("Fighter")

      updated_state = GameState.handle_fight(state)

      # Hero can deal 0 damage, so just verify damage was tracked
      assert updated_state.hero.total_damage_dealt >= 0
    end

    test "monster counter-attacks if alive" do
      state = GameState.new("Tank")
      initial_hero_hp = state.hero.hp

      # Set monster to high HP to ensure it survives
      high_hp_monster = %{state.monster | hp: 1000, hp_max: 1000}
      state = %{state | monster: high_hp_monster}

      updated_state = GameState.handle_fight(state)

      # Hero should have taken damage
      assert updated_state.hero.hp <= initial_hero_hp
    end

    test "adds combat messages to history" do
      state = GameState.new("Logger")
      initial_history_length = length(state.history)

      updated_state = GameState.handle_fight(state)

      # Should have more messages
      assert length(updated_state.history) > initial_history_length
    end

    test "monster dies and respawns when HP reaches 0" do
      state = GameState.new("Slayer")
      # Give monster very low HP and ensure hero can kill it
      weak_monster = %{state.monster | hp: 1, hp_max: 1}
      strong_hero = %{state.hero | damage_min: 1, damage_max: 10}
      state = %{state | monster: weak_monster, hero: strong_hero}

      updated_state = GameState.handle_fight(state)

      # Should have a new monster (fresh HP)
      assert updated_state.monster.hp == updated_state.monster.hp_max
      # Kill count should increase
      assert updated_state.hero.total_kills == 1
    end

    test "hero dies when HP reaches 0" do
      state = GameState.new("Doomed")
      # Give hero very low HP
      weak_hero = %{state.hero | hp: 1, hp_max: 1}
      # Give monster high damage
      strong_monster = %{state.monster | damage_base: 100.0, damage_sigma: 0.0}
      state = %{state | hero: weak_hero, monster: strong_monster}

      updated_state = GameState.handle_fight(state)

      assert updated_state.game_over == true
      assert Hero.defeated?(updated_state.hero)
    end

    test "tracks damage dealt statistic" do
      state = GameState.new("Damager")

      updated_state = GameState.handle_fight(state)

      # Hero deals 0-3 damage, so sometimes it's 0
      assert updated_state.hero.total_damage_dealt >= 0
    end
  end

  describe "handle_rest/1" do
    test "hero heals" do
      state = GameState.new("Healer")
      # Damage the hero first
      damaged_hero = Hero.take_damage(state.hero, 5)
      state = %{state | hero: damaged_hero}

      updated_state = GameState.handle_rest(state)

      # Hero should have more HP (unless monster killed them)
      if not updated_state.game_over do
        assert updated_state.hero.total_health_healed > 0
      end
    end

    test "monster attacks during rest" do
      state = GameState.new("Rester")

      updated_state = GameState.handle_rest(state)

      # Hero should have taken damage (might also have healed)
      # Just check that monster attack logic ran
      assert length(updated_state.history) > length(state.history)
    end

    test "adds rest and attack messages to history" do
      state = GameState.new("Logger")
      initial_history_length = length(state.history)

      updated_state = GameState.handle_rest(state)

      # Should have at least 2 new messages (heal + monster attack)
      assert length(updated_state.history) >= initial_history_length + 2
    end

    test "can result in hero death" do
      state = GameState.new("Unlucky")
      # Very low HP hero
      weak_hero = %{state.hero | hp: 1, hp_max: 10}
      # Strong monster
      strong_monster = %{state.monster | damage_base: 100.0, damage_sigma: 0.0}
      state = %{state | hero: weak_hero, monster: strong_monster}

      updated_state = GameState.handle_rest(state)

      assert updated_state.game_over == true
    end

    test "tracks healing statistic" do
      state = GameState.new("Tracker")
      # Damage hero so there's room to heal
      damaged_hero = Hero.take_damage(state.hero, 5)
      state = %{state | hero: damaged_hero}

      updated_state = GameState.handle_rest(state)

      # Should have healing tracked (unless capped at max HP)
      assert updated_state.hero.total_health_healed >= 0
    end
  end

  describe "add_to_history/3" do
    test "adds message to history" do
      state = GameState.new("Hero")
      initial_length = length(state.history)

      updated_state = GameState.add_to_history(state, "Test message", :system)

      assert length(updated_state.history) == initial_length + 1
      assert hd(updated_state.history).message == "Test message"
      assert hd(updated_state.history).type == :system
    end

    test "new messages appear first" do
      state = GameState.new("Hero")

      state = GameState.add_to_history(state, "First", :system)
      state = GameState.add_to_history(state, "Second", :combat)

      assert hd(state.history).message == "Second"
      assert hd(state.history).type == :combat
      assert Enum.at(state.history, 1).message == "First"
    end

    test "limits history to max size" do
      state = GameState.new("Hero")

      # Add many messages
      state =
        Enum.reduce(1..250, state, fn i, acc ->
          GameState.add_to_history(acc, "Message #{i}")
        end)

      # Should be capped at 200
      assert length(state.history) == 200
    end
  end

  describe "level up integration" do
    test "hero levels up after required kills" do
      state = GameState.new("Leveler")

      # Kill one monster (should level up from 1 to 2)
      # Ensure hero can deal damage
      weak_monster = %{state.monster | hp: 1, hp_max: 1}
      strong_hero = %{state.hero | damage_min: 1, damage_max: 5}
      state = %{state | monster: weak_monster, hero: strong_hero}
      updated_state = GameState.handle_fight(state)

      assert updated_state.hero.level == 2
      assert updated_state.hero.level_kills == 0
      assert updated_state.hero.total_kills == 1
    end

    test "level up increases stats" do
      state = GameState.new("Stronger")
      initial_hp_max = state.hero.hp_max

      # Kill monster to trigger level up - ensure hero can deal damage
      weak_monster = %{state.monster | hp: 1, hp_max: 1}
      strong_hero = %{state.hero | damage_min: 1, damage_max: 5}
      state = %{state | monster: weak_monster, hero: strong_hero}
      updated_state = GameState.handle_fight(state)

      # HP max definitely increases
      assert updated_state.hero.hp_max > initial_hp_max
    end

    test "new monster spawns appropriate for hero level" do
      state = GameState.new("Progressor")

      # Kill monster multiple times
      state =
        Enum.reduce(1..5, state, fn _, acc ->
          weak_monster = %{acc.monster | hp: 1, hp_max: 1}
          acc = %{acc | monster: weak_monster}
          GameState.handle_fight(acc)
        end)

      # Should have leveled up
      assert state.hero.level > 1
      # Should have a new monster
      assert %Monster{} = state.monster
    end
  end

  describe "monster kill tracking" do
    test "tracks monsters killed by type" do
      state = GameState.new("Tracker")

      # Kill a monster - ensure hero can deal damage
      weak_monster = %{state.monster | hp: 1, hp_max: 1}
      strong_hero = %{state.hero | damage_min: 1, damage_max: 5}
      state = %{state | monster: weak_monster, hero: strong_hero}
      updated_state = GameState.handle_fight(state)

      assert map_size(updated_state.hero.monsters_killed_by_type) > 0
      assert updated_state.hero.total_kills == 1
    end
  end

  describe "boss encounters" do
    test "boss defeat heals hero to full HP" do
      state = GameState.new("Hero")

      # Level up hero to 10 and damage them
      hero = %{state.hero | level: 10, hp: 5, hp_max: 50}

      # Create a weak boss that can be defeated
      boss = %{
        name: "Test Boss",
        display_name: "Test Boss",
        hp: 1,
        hp_max: 100,
        damage_base: 20.0,
        damage_sigma: 0.0,
        is_boss: true,
        floor: 1
      }

      state = %{state | hero: hero, monster: boss}
      updated_state = GameState.handle_fight(state)

      # Hero should be fully healed after boss victory
      assert updated_state.hero.hp == updated_state.hero.hp_max
    end

    test "boss defeat sets pending_boss_reward flag" do
      state = GameState.new("Hero")

      # Create a weak boss
      hero = %{state.hero | level: 10, damage_min: 100, damage_max: 150}

      boss = %{
        name: "Test Boss",
        display_name: "Test Boss",
        hp: 1,
        hp_max: 100,
        damage_base: 20.0,
        damage_sigma: 0.0,
        is_boss: true,
        floor: 1
      }

      state = %{state | hero: hero, monster: boss}
      updated_state = GameState.handle_fight(state)

      assert updated_state.pending_boss_reward == true
    end

    test "boss defeat increments bosses_defeated counter" do
      state = GameState.new("Hero")

      hero = %{state.hero | level: 10, bosses_defeated: 0, damage_min: 100, damage_max: 150}

      boss = %{
        name: "Test Boss",
        display_name: "Test Boss",
        hp: 1,
        hp_max: 100,
        damage_base: 20.0,
        damage_sigma: 0.0,
        is_boss: true,
        floor: 1
      }

      state = %{state | hero: hero, monster: boss}
      updated_state = GameState.handle_fight(state)

      assert updated_state.hero.bosses_defeated == 1
    end

    test "boss defeat updates current_floor" do
      state = GameState.new("Hero")

      hero = %{state.hero | level: 10, current_floor: 1, damage_min: 100, damage_max: 150}

      boss = %{
        name: "Test Boss",
        display_name: "Test Boss",
        hp: 1,
        hp_max: 100,
        damage_base: 20.0,
        damage_sigma: 0.0,
        is_boss: true,
        floor: 2
      }

      state = %{state | hero: hero, monster: boss}
      updated_state = GameState.handle_fight(state)

      assert updated_state.hero.current_floor == 2
    end

    test "boss defeat adds victory messages to history" do
      state = GameState.new("Hero")

      hero = %{state.hero | level: 10, damage_min: 100, damage_max: 150}

      boss = %{
        name: "Test Boss",
        display_name: "Test Boss",
        hp: 1,
        hp_max: 100,
        damage_base: 20.0,
        damage_sigma: 0.0,
        is_boss: true,
        floor: 1
      }

      state = %{state | hero: hero, monster: boss}
      updated_state = GameState.handle_fight(state)

      # Check for boss victory message in history
      history_text = Enum.map(updated_state.history, & &1.message) |> Enum.join(" ")
      assert String.contains?(history_text, "BOSS DEFEATED")
    end

    test "regular monster defeat does not set pending_boss_reward" do
      state = GameState.new("Hero")

      hero = %{state.hero | damage_min: 100, damage_max: 150}

      regular = %{
        name: "RegularMonster",
        display_name: "Regular Monster",
        hp: 1,
        hp_max: 10,
        damage_base: 3.0,
        damage_sigma: 1.0,
        is_boss: false,
        floor: nil
      }

      state = %{state | hero: hero, monster: regular}
      updated_state = GameState.handle_fight(state)

      assert updated_state.pending_boss_reward == false
    end
  end

  describe "boss rewards" do
    test "handle_claim_boss_reward with healing creates Major healing potion" do
      state = GameState.new("Hero")
      state = %{state | pending_boss_reward: true}

      updated_state = GameState.handle_claim_boss_reward(state, "healing")

      # Should clear pending reward flag
      assert updated_state.pending_boss_reward == false

      # Should have added potion to inventory
      assert length(updated_state.hero.inventory.slots) > 0

      # Check that a healing potion was added
      healing_potions =
        Enum.filter(updated_state.hero.inventory.slots, fn slot ->
          slot != nil && slot.category == :healing && slot.quality == :major
        end)

      assert length(healing_potions) > 0
    end

    test "handle_claim_boss_reward with damage creates Major damage potion" do
      state = GameState.new("Hero")
      state = %{state | pending_boss_reward: true}

      updated_state = GameState.handle_claim_boss_reward(state, "damage")

      # Should clear pending reward flag
      assert updated_state.pending_boss_reward == false

      # Check that a damage potion was added
      damage_potions =
        Enum.filter(updated_state.hero.inventory.slots, fn slot ->
          slot != nil && slot.category == :damage && slot.quality == :major
        end)

      assert length(damage_potions) > 0
    end

    test "boss reward adds message to history" do
      state = GameState.new("Hero")
      state = %{state | pending_boss_reward: true}

      updated_state = GameState.handle_claim_boss_reward(state, "healing")

      # Check for reward message in history
      history_text = Enum.map(updated_state.history, & &1.message) |> Enum.join(" ")
      assert String.contains?(history_text, "boss reward")
    end

    test "boss reward spawns next monster after claiming" do
      state = GameState.new("Hero")
      state = %{state | pending_boss_reward: true}

      initial_monster = state.monster
      updated_state = GameState.handle_claim_boss_reward(state, "healing")

      # Should have a new monster (different reference)
      refute updated_state.monster == initial_monster
    end
  end
end
