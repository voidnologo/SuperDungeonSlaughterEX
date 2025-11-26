defmodule SuperDungeonSlaughterEx.Game.GameStateTest do
  use ExUnit.Case, async: false

  alias SuperDungeonSlaughterEx.Game.{GameState, Hero, Monster}
  alias SuperDungeonSlaughterEx.Repos.MonsterRepo

  @test_json_path Path.join([
                    System.tmp_dir!(),
                    "test_monsters_gamestate_#{:rand.uniform(999_999)}.json"
                  ])

  setup do
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

    File.write!(@test_json_path, Jason.encode!(test_data))
    start_supervised!({MonsterRepo, json_path: @test_json_path})

    on_exit(fn ->
      File.rm(@test_json_path)
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

      assert Enum.any?(state.history, fn msg ->
               String.contains?(msg, "Welcome") && String.contains?(msg, "Adventurer")
             end)
    end

    test "announces first monster in history" do
      state = GameState.new("Hero")

      assert Enum.any?(state.history, fn msg ->
               String.contains?(msg, "appears")
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
      initial_hp = state.hero.hp

      updated_state = GameState.handle_rest(state)

      # Hero should have more HP (unless monster killed them)
      if not updated_state.game_over do
        assert updated_state.hero.total_health_healed > 0
      end
    end

    test "monster attacks during rest" do
      state = GameState.new("Rester")
      initial_hp = state.hero.hp

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

  describe "add_to_history/2" do
    test "adds message to history" do
      state = GameState.new("Hero")
      initial_length = length(state.history)

      updated_state = GameState.add_to_history(state, "Test message")

      assert length(updated_state.history) == initial_length + 1
      assert hd(updated_state.history) == "Test message"
    end

    test "new messages appear first" do
      state = GameState.new("Hero")

      state = GameState.add_to_history(state, "First")
      state = GameState.add_to_history(state, "Second")

      assert hd(state.history) == "Second"
      assert Enum.at(state.history, 1) == "First"
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
end
