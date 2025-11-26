defmodule SuperDungeonSlaughterEx.Game.PotionTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.Potion

  describe "new/3" do
    test "creates a minor healing potion" do
      potion = Potion.new(:minor, :healing)

      assert potion.quality == :minor
      assert potion.category == :healing
      assert potion.flavor == nil
      assert potion.display_name == "Minor Healing Potion"
      assert is_binary(potion.id)
    end

    test "creates a normal healing potion" do
      potion = Potion.new(:normal, :healing)

      assert potion.quality == :normal
      assert potion.category == :healing
      assert potion.display_name == "Normal Healing Potion"
    end

    test "creates a major healing potion" do
      potion = Potion.new(:major, :healing)

      assert potion.quality == :major
      assert potion.category == :healing
      assert potion.display_name == "Major Healing Potion"
    end

    test "creates a damage potion with fire flavor" do
      potion = Potion.new(:minor, :damage, :fire)

      assert potion.quality == :minor
      assert potion.category == :damage
      assert potion.flavor == :fire
      assert potion.display_name == "Minor Fire Potion"
    end

    test "creates damage potions with various flavors" do
      flavors = [:fire, :acid, :lightning, :poison, :frost, :arcane, :shadow, :radiant]

      for flavor <- flavors do
        potion = Potion.new(:normal, :damage, flavor)
        assert potion.flavor == flavor
        assert String.contains?(potion.display_name, "Normal")
      end
    end

    test "each potion has a unique ID" do
      potion1 = Potion.new(:minor, :healing)
      potion2 = Potion.new(:minor, :healing)

      assert potion1.id != potion2.id
    end
  end

  describe "calculate_healing/2" do
    test "minor healing potion heals 25% of max HP" do
      potion = Potion.new(:minor, :healing)
      assert Potion.calculate_healing(potion, 100) == 25
      assert Potion.calculate_healing(potion, 50) == 12
      assert Potion.calculate_healing(potion, 33) == 8
    end

    test "normal healing potion heals 50% of max HP" do
      potion = Potion.new(:normal, :healing)
      assert Potion.calculate_healing(potion, 100) == 50
      assert Potion.calculate_healing(potion, 50) == 25
      assert Potion.calculate_healing(potion, 33) == 16
    end

    test "major healing potion heals 100% of max HP" do
      potion = Potion.new(:major, :healing)
      assert Potion.calculate_healing(potion, 100) == 100
      assert Potion.calculate_healing(potion, 50) == 50
      assert Potion.calculate_healing(potion, 33) == 33
    end

    test "damage potion returns 0 healing" do
      potion = Potion.new(:minor, :damage, :fire)
      assert Potion.calculate_healing(potion, 100) == 0
    end
  end

  describe "calculate_damage/2" do
    test "minor damage potion deals 25% of current HP" do
      potion = Potion.new(:minor, :damage, :fire)
      assert Potion.calculate_damage(potion, 100) == 25
      assert Potion.calculate_damage(potion, 50) == 12
      assert Potion.calculate_damage(potion, 33) == 8
    end

    test "normal damage potion deals 50% of current HP" do
      potion = Potion.new(:normal, :damage, :acid)
      assert Potion.calculate_damage(potion, 100) == 50
      assert Potion.calculate_damage(potion, 50) == 25
      assert Potion.calculate_damage(potion, 33) == 16
    end

    test "major damage potion deals 100% of current HP" do
      potion = Potion.new(:major, :damage, :lightning)
      assert Potion.calculate_damage(potion, 100) == 100
      assert Potion.calculate_damage(potion, 50) == 50
      assert Potion.calculate_damage(potion, 33) == 33
    end

    test "healing potion returns 0 damage" do
      potion = Potion.new(:minor, :healing)
      assert Potion.calculate_damage(potion, 100) == 0
    end
  end

  describe "get_icon/1" do
    test "minor potions have test tube icon" do
      potion = Potion.new(:minor, :healing)
      assert Potion.get_icon(potion) == "🧪"
    end

    test "normal potions have flask icon" do
      potion = Potion.new(:normal, :healing)
      assert Potion.get_icon(potion) == "⚗️"
    end

    test "major potions have large container icon" do
      potion = Potion.new(:major, :healing)
      assert Potion.get_icon(potion) == "🏺"
    end
  end

  describe "get_icon_size_class/1" do
    test "minor potions have small size class" do
      potion = Potion.new(:minor, :healing)
      assert Potion.get_icon_size_class(potion) == "text-sm"
    end

    test "normal potions have base size class" do
      potion = Potion.new(:normal, :healing)
      assert Potion.get_icon_size_class(potion) == "text-base"
    end

    test "major potions have large size class" do
      potion = Potion.new(:major, :healing)
      assert Potion.get_icon_size_class(potion) == "text-xl"
    end
  end

  describe "get_color_class/1" do
    test "healing potions have green color classes" do
      minor = Potion.new(:minor, :healing)
      normal = Potion.new(:normal, :healing)
      major = Potion.new(:major, :healing)

      assert Potion.get_color_class(minor) == "text-green-300"
      assert Potion.get_color_class(normal) == "text-green-400"
      assert Potion.get_color_class(major) == "text-green-500"
    end

    test "damage potions have flavor-specific color classes" do
      fire = Potion.new(:minor, :damage, :fire)
      acid = Potion.new(:minor, :damage, :acid)
      lightning = Potion.new(:minor, :damage, :lightning)
      poison = Potion.new(:minor, :damage, :poison)

      assert Potion.get_color_class(fire) == "text-orange-500"
      assert Potion.get_color_class(acid) == "text-lime-400"
      assert Potion.get_color_class(lightning) == "text-blue-400"
      assert Potion.get_color_class(poison) == "text-purple-500"
    end
  end

  describe "get_bg_color_class/1" do
    test "healing potions have appropriate background colors" do
      minor = Potion.new(:minor, :healing)
      normal = Potion.new(:normal, :healing)
      major = Potion.new(:major, :healing)

      assert Potion.get_bg_color_class(minor) == "bg-green-900"
      assert Potion.get_bg_color_class(normal) == "bg-green-800"
      assert Potion.get_bg_color_class(major) == "bg-green-700"
    end

    test "damage potions have flavor-specific background colors" do
      fire = Potion.new(:minor, :damage, :fire)
      frost = Potion.new(:minor, :damage, :frost)

      assert Potion.get_bg_color_class(fire) == "bg-orange-900"
      assert Potion.get_bg_color_class(frost) == "bg-cyan-900"
    end
  end

  describe "get_border_color_class/1" do
    test "healing potions have green border" do
      potion = Potion.new(:minor, :healing)
      assert Potion.get_border_color_class(potion) == "border-green-500"
    end

    test "damage potions have flavor-specific borders" do
      fire = Potion.new(:minor, :damage, :fire)
      arcane = Potion.new(:minor, :damage, :arcane)

      assert Potion.get_border_color_class(fire) == "border-orange-500"
      assert Potion.get_border_color_class(arcane) == "border-pink-500"
    end
  end
end
