defmodule SuperDungeonSlaughterEx.Game.HeroTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.Hero

  describe "new/1" do
    test "creates a hero with starting stats" do
      hero = Hero.new("TestHero")

      assert hero.name == "TestHero"
      assert hero.level == 1
      assert hero.hp == 10
      assert hero.hp_max == 10
      assert hero.total_kills == 0
      assert hero.level_kills == 0
      assert hero.damage_min == 0
      assert hero.damage_max == 3
      assert hero.heal_min == 1
      assert hero.heal_max == 4
      assert hero.total_damage_dealt == 0
      assert hero.total_health_healed == 0
      assert hero.monsters_killed_by_type == %{}
    end
  end

  describe "attack/1" do
    test "deals damage within range and updates statistics" do
      hero = Hero.new("Attacker")

      {updated_hero, damage} = Hero.attack(hero)

      assert damage >= hero.damage_min
      assert damage <= hero.damage_max
      assert updated_hero.total_damage_dealt == damage
    end

    test "accumulates damage dealt over multiple attacks" do
      hero = Hero.new("Attacker")

      {hero, damage1} = Hero.attack(hero)
      {hero, damage2} = Hero.attack(hero)

      assert hero.total_damage_dealt == damage1 + damage2
    end
  end

  describe "take_damage/2" do
    test "reduces HP by damage amount" do
      hero = Hero.new("Tank")
      damaged_hero = Hero.take_damage(hero, 5)

      assert damaged_hero.hp == 5
    end

    test "does not reduce HP below 0" do
      hero = Hero.new("Fragile")
      damaged_hero = Hero.take_damage(hero, 999)

      assert damaged_hero.hp == 0
    end

    test "handles zero damage" do
      hero = Hero.new("Lucky")
      damaged_hero = Hero.take_damage(hero, 0)

      assert damaged_hero.hp == hero.hp
    end
  end

  describe "rest/1" do
    test "heals within range and updates statistics" do
      hero = Hero.new("Healer") |> Hero.take_damage(5)

      {healed_hero, heal_amount} = Hero.rest(hero)

      assert heal_amount >= hero.heal_min
      assert heal_amount <= hero.heal_max
      assert healed_hero.hp == hero.hp + heal_amount
      assert healed_hero.total_health_healed == heal_amount
    end

    test "does not heal above max HP" do
      hero = Hero.new("FullHealth")

      {healed_hero, heal_amount} = Hero.rest(hero)

      assert healed_hero.hp == hero.hp_max
      assert heal_amount == 0
      assert healed_hero.total_health_healed == 0
    end

    test "accumulates healing over multiple rests" do
      hero = Hero.new("Healer") |> Hero.take_damage(8)

      {hero, heal1} = Hero.rest(hero)
      {hero, heal2} = Hero.rest(hero)

      assert hero.total_health_healed == heal1 + heal2
    end
  end

  describe "record_kill/2" do
    test "increments kill counters and tracks monster type" do
      hero = Hero.new("Slayer")

      updated_hero = Hero.record_kill(hero, "Goblin")

      assert updated_hero.total_kills == 1
      assert updated_hero.level_kills == 1
      assert updated_hero.monsters_killed_by_type["Goblin"] == 1
    end

    test "tracks multiple kills of same monster type" do
      hero = Hero.new("Slayer")

      hero = Hero.record_kill(hero, "Goblin")
      hero = Hero.record_kill(hero, "Goblin")
      hero = Hero.record_kill(hero, "Goblin")

      assert hero.total_kills == 3
      assert hero.monsters_killed_by_type["Goblin"] == 3
    end

    test "tracks multiple different monster types" do
      hero = Hero.new("Slayer")

      hero = Hero.record_kill(hero, "Goblin")
      hero = Hero.record_kill(hero, "Orc")
      hero = Hero.record_kill(hero, "Kobold")

      assert hero.total_kills == 3
      assert hero.monsters_killed_by_type["Goblin"] == 1
      assert hero.monsters_killed_by_type["Orc"] == 1
      assert hero.monsters_killed_by_type["Kobold"] == 1
    end
  end

  describe "should_level_up?/1" do
    test "returns false for new hero" do
      hero = Hero.new("Newbie")
      refute Hero.should_level_up?(hero)
    end

    test "returns true when level_kills equals level" do
      hero = Hero.new("Leveler") |> Map.put(:level_kills, 1)
      assert Hero.should_level_up?(hero)
    end

    test "returns false when level_kills is 0" do
      hero = Hero.new("Zero")
      refute Hero.should_level_up?(hero)
    end

    test "returns true at level 3 with 3 kills" do
      hero = %Hero{Hero.new("Test") | level: 3, level_kills: 3}
      assert Hero.should_level_up?(hero)
    end

    test "returns false at level 3 with 2 kills" do
      hero = %Hero{Hero.new("Test") | level: 3, level_kills: 2}
      refute Hero.should_level_up?(hero)
    end
  end

  describe "level_up/1" do
    test "increases level and stats when threshold met" do
      hero = %Hero{Hero.new("Leveler") | level_kills: 1}

      leveled_hero = Hero.level_up(hero)

      assert leveled_hero.level == 2
      assert leveled_hero.hp_max == 12  # 10 + 2
      assert leveled_hero.level_kills == 0
      assert leveled_hero.damage_min >= hero.damage_min
      assert leveled_hero.damage_max >= hero.damage_max
      assert leveled_hero.heal_min >= hero.heal_min
      assert leveled_hero.heal_max >= hero.heal_max
    end

    test "does not level up when threshold not met" do
      hero = Hero.new("NotReady")

      leveled_hero = Hero.level_up(hero)

      assert leveled_hero.level == 1
    end

    test "scales damage by 10%" do
      hero = %Hero{Hero.new("Damage") | level_kills: 1, damage_min: 10, damage_max: 20}

      leveled_hero = Hero.level_up(hero)

      assert leveled_hero.damage_min == 11  # ceil(10 * 1.1) = 11
      assert leveled_hero.damage_max == 22  # ceil(20 * 1.1) = 22
    end

    test "scales heal by 15%" do
      hero = %Hero{Hero.new("Healer") | level_kills: 1, heal_min: 10, heal_max: 20}

      leveled_hero = Hero.level_up(hero)

      assert leveled_hero.heal_min == 12  # ceil(10 * 1.15) = 12
      assert leveled_hero.heal_max == 23  # ceil(20 * 1.15) = 23
    end

    test "handles zero stats correctly" do
      hero = %Hero{Hero.new("Zero") | level_kills: 1, damage_min: 0}

      leveled_hero = Hero.level_up(hero)

      assert leveled_hero.damage_min == 1  # 0 -> 1
    end
  end

  describe "hp_percentage/1" do
    test "returns 1.0 for full health" do
      hero = Hero.new("Full")
      assert Hero.hp_percentage(hero) == 1.0
    end

    test "returns 0.5 for half health" do
      hero = Hero.new("Half") |> Hero.take_damage(5)
      assert Hero.hp_percentage(hero) == 0.5
    end

    test "returns 0.0 for zero health" do
      hero = Hero.new("Dead") |> Hero.take_damage(10)
      assert Hero.hp_percentage(hero) == 0.0
    end

    test "handles edge cases" do
      hero = %Hero{Hero.new("Edge") | hp: 1, hp_max: 10}
      assert Hero.hp_percentage(hero) == 0.1
    end
  end

  describe "defeated?/1" do
    test "returns false for alive hero" do
      hero = Hero.new("Alive")
      refute Hero.defeated?(hero)
    end

    test "returns true for zero HP" do
      hero = Hero.new("Dead") |> Hero.take_damage(10)
      assert Hero.defeated?(hero)
    end

    test "returns false for 1 HP" do
      hero = Hero.new("Barely") |> Hero.take_damage(9)
      refute Hero.defeated?(hero)
    end
  end

  describe "get_statistics/1" do
    test "returns comprehensive statistics" do
      hero =
        Hero.new("Stats")
        |> Map.put(:level, 5)
        |> Map.put(:total_kills, 20)
        |> Map.put(:total_damage_dealt, 500)
        |> Map.put(:total_health_healed, 100)
        |> Map.put(:monsters_killed_by_type, %{"Goblin" => 10, "Orc" => 5, "Kobold" => 5})

      stats = Hero.get_statistics(hero)

      assert stats.level == 5
      assert stats.kills == 20
      assert stats.damage_dealt == 500
      assert stats.health_healed == 100
      assert is_list(stats.monster_breakdown)
      assert length(stats.monster_breakdown) == 3
    end

    test "sorts monster breakdown by count descending" do
      hero =
        Hero.new("Stats")
        |> Map.put(:monsters_killed_by_type, %{"Goblin" => 10, "Orc" => 5, "Kobold" => 15})

      stats = Hero.get_statistics(hero)

      assert [{name, count} | _] = stats.monster_breakdown
      assert name == "Kobold"
      assert count == 15
    end
  end
end
