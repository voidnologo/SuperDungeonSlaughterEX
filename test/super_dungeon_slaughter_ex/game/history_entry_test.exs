defmodule SuperDungeonSlaughterEx.Game.HistoryEntryTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.HistoryEntry

  describe "new/2" do
    test "creates a combat entry with correct icon" do
      entry = HistoryEntry.new("Hero attacks!", :combat)

      assert entry.message == "Hero attacks!"
      assert entry.type == :combat
      assert entry.icon == "🗡️"
    end

    test "creates a healing entry with correct icon" do
      entry = HistoryEntry.new("Hero heals 10 HP", :healing)

      assert entry.message == "Hero heals 10 HP"
      assert entry.type == :healing
      assert entry.icon == "❤️"
    end

    test "creates a victory entry with correct icon" do
      entry = HistoryEntry.new("Monster defeated!", :victory)

      assert entry.type == :victory
      assert entry.icon == "⭐"
    end

    test "creates an item entry with correct icon" do
      entry = HistoryEntry.new("Potion dropped!", :item)

      assert entry.type == :item
      assert entry.icon == "🎁"
    end

    test "creates a level_up entry with correct icon" do
      entry = HistoryEntry.new("LEVEL UP!", :level_up)

      assert entry.type == :level_up
      assert entry.icon == "🎉"
    end

    test "creates a death entry with correct icon" do
      entry = HistoryEntry.new("You died!", :death)

      assert entry.type == :death
      assert entry.icon == "💀"
    end

    test "creates a system entry with correct icon" do
      entry = HistoryEntry.new("Welcome!", :system)

      assert entry.type == :system
      assert entry.icon == "📢"
    end
  end

  describe "get_color_class/1" do
    test "returns correct color class for combat" do
      assert HistoryEntry.get_color_class(:combat) == "text-green-300"
    end

    test "returns correct color class for healing" do
      assert HistoryEntry.get_color_class(:healing) == "text-green-400"
    end

    test "returns correct color class for victory" do
      assert HistoryEntry.get_color_class(:victory) == "text-yellow-300"
    end

    test "returns correct color class for item" do
      assert HistoryEntry.get_color_class(:item) == "text-purple-400"
    end

    test "returns correct color class for level_up" do
      assert HistoryEntry.get_color_class(:level_up) == "text-cyan-400"
    end

    test "returns correct color class for death" do
      assert HistoryEntry.get_color_class(:death) == "text-red-400"
    end

    test "returns correct color class for system" do
      assert HistoryEntry.get_color_class(:system) == "text-gray-400"
    end
  end

  describe "separator/1" do
    test "creates a separator entry with level_up type by default" do
      entry = HistoryEntry.separator()

      assert entry.type == :level_up
      assert entry.icon == "🎉"
      assert entry.message == "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    end

    test "creates a separator entry with custom type" do
      entry = HistoryEntry.separator(:victory)

      assert entry.type == :victory
      assert entry.icon == "⭐"
      assert entry.message == "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    end
  end
end
