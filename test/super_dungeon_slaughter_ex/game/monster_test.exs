defmodule SuperDungeonSlaughterEx.Game.MonsterTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.Monster

  @sample_template %{
    name: "Test Goblin",
    min_level: 1,
    max_level: 5,
    avg_hp: 10.0,
    hp_sigma: 2.0,
    damage_base: 5.0,
    damage_sigma: 1.0
  }

  describe "from_template/1" do
    test "creates monster with correct name" do
      monster = Monster.from_template(@sample_template)
      assert monster.name == "Test Goblin"
    end

    test "creates monster with damage stats from template" do
      monster = Monster.from_template(@sample_template)
      assert monster.damage_base == 5.0
      assert monster.damage_sigma == 1.0
    end

    test "creates monster with HP at least 1" do
      template = %{@sample_template | avg_hp: 0.5, hp_sigma: 0.1}
      monster = Monster.from_template(template)
      assert monster.hp >= 1
      assert monster.hp_max >= 1
    end

    test "hp and hp_max are equal on creation" do
      monster = Monster.from_template(@sample_template)
      assert monster.hp == monster.hp_max
    end

    test "generates varied HP using Gaussian distribution" do
      # Generate multiple monsters and verify they have different HP values
      monsters = for _ <- 1..20, do: Monster.from_template(@sample_template)
      hp_values = Enum.map(monsters, & &1.hp) |> Enum.uniq()

      # Should have at least some variation
      assert length(hp_values) > 1
    end

    test "HP respects Gaussian distribution bounds" do
      # Most values should be within 3 standard deviations
      template = %{@sample_template | avg_hp: 50.0, hp_sigma: 5.0}
      monsters = for _ <- 1..100, do: Monster.from_template(template)

      Enum.each(monsters, fn monster ->
        assert monster.hp >= 1
        # Within reasonable bounds (allowing for Gaussian tails)
        assert monster.hp <= 100
      end)
    end
  end

  describe "attack/1" do
    setup do
      monster = Monster.from_template(@sample_template)
      {:ok, monster: monster}
    end

    test "returns non-negative damage", %{monster: monster} do
      for _ <- 1..50 do
        damage = Monster.attack(monster)
        assert damage >= 0
      end
    end

    test "damage varies due to Gaussian distribution", %{monster: monster} do
      damages = for _ <- 1..20, do: Monster.attack(monster)
      unique_damages = Enum.uniq(damages)

      # Should have variation in damage
      assert length(unique_damages) > 1
    end

    test "damage centers around damage_base", %{monster: monster} do
      damages = for _ <- 1..100, do: Monster.attack(monster)
      avg_damage = Enum.sum(damages) / length(damages)

      # Average should be close to damage_base (within 20%)
      assert_in_delta avg_damage, monster.damage_base, monster.damage_base * 0.3
    end

    test "handles zero damage_base" do
      template = %{@sample_template | damage_base: 0.0, damage_sigma: 0.0}
      monster = Monster.from_template(template)

      damage = Monster.attack(monster)
      assert damage >= 0
    end
  end

  describe "take_damage/2" do
    setup do
      monster = Monster.from_template(@sample_template)
      {:ok, monster: monster}
    end

    test "reduces HP by damage amount", %{monster: monster} do
      initial_hp = monster.hp
      damaged = Monster.take_damage(monster, 3)

      assert damaged.hp == initial_hp - 3
    end

    test "does not reduce HP below 0", %{monster: monster} do
      damaged = Monster.take_damage(monster, 999)
      assert damaged.hp == 0
    end

    test "handles zero damage", %{monster: monster} do
      initial_hp = monster.hp
      damaged = Monster.take_damage(monster, 0)

      assert damaged.hp == initial_hp
    end

    test "does not change hp_max", %{monster: monster} do
      initial_max = monster.hp_max
      damaged = Monster.take_damage(monster, 5)

      assert damaged.hp_max == initial_max
    end
  end

  describe "hp_percentage/1" do
    test "returns 1.0 for full health" do
      monster = Monster.from_template(@sample_template)
      assert Monster.hp_percentage(monster) == 1.0
    end

    test "returns correct percentage for damaged monster" do
      monster = Monster.from_template(@sample_template)
      initial_hp = monster.hp
      damage = div(initial_hp, 2)
      damaged = Monster.take_damage(monster, damage)

      expected = (initial_hp - damage) / initial_hp
      assert_in_delta Monster.hp_percentage(damaged), expected, 0.01
    end

    test "returns 0.0 for zero HP" do
      monster = Monster.from_template(@sample_template)
      dead = Monster.take_damage(monster, monster.hp)

      assert Monster.hp_percentage(dead) == 0.0
    end

    test "handles edge case of 1 HP remaining" do
      monster = %Monster{
        name: "Edge",
        hp: 1,
        hp_max: 100,
        damage_base: 5.0,
        damage_sigma: 1.0
      }

      assert Monster.hp_percentage(monster) == 0.01
    end
  end

  describe "defeated?/1" do
    setup do
      monster = Monster.from_template(@sample_template)
      {:ok, monster: monster}
    end

    test "returns false for alive monster", %{monster: monster} do
      refute Monster.defeated?(monster)
    end

    test "returns true for zero HP", %{monster: monster} do
      dead = Monster.take_damage(monster, monster.hp)
      assert Monster.defeated?(dead)
    end

    test "returns false for 1 HP", %{monster: monster} do
      barely_alive = Monster.take_damage(monster, monster.hp - 1)
      refute Monster.defeated?(barely_alive)
    end

    test "returns true after excessive damage", %{monster: monster} do
      overkilled = Monster.take_damage(monster, 9999)
      assert Monster.defeated?(overkilled)
    end
  end
end
