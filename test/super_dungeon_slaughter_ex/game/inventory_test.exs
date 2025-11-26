defmodule SuperDungeonSlaughterEx.Game.InventoryTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Game.{Inventory, Potion}

  describe "new/0" do
    test "creates an empty inventory with 5 slots" do
      inventory = Inventory.new()

      assert length(inventory.slots) == 5
      assert Enum.all?(inventory.slots, &is_nil/1)
    end
  end

  describe "new_with_starter/0" do
    test "creates inventory with normal healing potion in first slot" do
      inventory = Inventory.new_with_starter()

      assert length(inventory.slots) == 5

      first_potion = Enum.at(inventory.slots, 0)
      assert first_potion.quality == :normal
      assert first_potion.category == :healing

      # Rest of slots are empty
      assert Enum.at(inventory.slots, 1) == nil
      assert Enum.at(inventory.slots, 2) == nil
      assert Enum.at(inventory.slots, 3) == nil
      assert Enum.at(inventory.slots, 4) == nil
    end
  end

  describe "add_potion/2" do
    test "adds potion to first empty slot" do
      inventory = Inventory.new()
      potion = Potion.new(:minor, :healing)

      {:ok, updated} = Inventory.add_potion(inventory, potion)

      assert Enum.at(updated.slots, 0) == potion
      assert Enum.at(updated.slots, 1) == nil
    end

    test "adds multiple potions to sequential slots" do
      inventory = Inventory.new()
      potion1 = Potion.new(:minor, :healing)
      potion2 = Potion.new(:normal, :damage, :fire)

      {:ok, inventory} = Inventory.add_potion(inventory, potion1)
      {:ok, inventory} = Inventory.add_potion(inventory, potion2)

      assert Enum.at(inventory.slots, 0) == potion1
      assert Enum.at(inventory.slots, 1) == potion2
      assert Enum.at(inventory.slots, 2) == nil
    end

    test "returns {:full, inventory} when all slots occupied" do
      inventory = Inventory.new()

      # Fill all 5 slots
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))

      # Try to add 6th potion
      extra_potion = Potion.new(:major, :healing)
      assert {:full, ^inventory} = Inventory.add_potion(inventory, extra_potion)
    end
  end

  describe "remove_potion/2" do
    test "removes potion from valid slot" do
      inventory = Inventory.new()
      potion = Potion.new(:minor, :healing)
      {:ok, inventory} = Inventory.add_potion(inventory, potion)

      {:ok, updated, removed} = Inventory.remove_potion(inventory, 0)

      assert removed == potion
      assert Enum.at(updated.slots, 0) == nil
    end

    test "returns error for invalid slot index" do
      inventory = Inventory.new()

      assert {:error, :invalid_slot} = Inventory.remove_potion(inventory, -1)
      assert {:error, :invalid_slot} = Inventory.remove_potion(inventory, 5)
      assert {:error, :invalid_slot} = Inventory.remove_potion(inventory, 10)
    end

    test "returns error for empty slot" do
      inventory = Inventory.new()

      assert {:error, :empty_slot} = Inventory.remove_potion(inventory, 0)
    end

    test "fills gap when removing from middle slot" do
      inventory = Inventory.new()
      potion1 = Potion.new(:minor, :healing)
      potion2 = Potion.new(:normal, :healing)
      potion3 = Potion.new(:major, :healing)

      {:ok, inventory} = Inventory.add_potion(inventory, potion1)
      {:ok, inventory} = Inventory.add_potion(inventory, potion2)
      {:ok, inventory} = Inventory.add_potion(inventory, potion3)

      # Remove middle potion
      {:ok, inventory, _removed} = Inventory.remove_potion(inventory, 1)

      # Gap is created (slot 1 is now nil)
      assert Enum.at(inventory.slots, 0) == potion1
      assert Enum.at(inventory.slots, 1) == nil
      assert Enum.at(inventory.slots, 2) == potion3

      # Can add new potion to fill the gap
      new_potion = Potion.new(:minor, :damage, :fire)
      {:ok, inventory} = Inventory.add_potion(inventory, new_potion)
      assert Enum.at(inventory.slots, 1) == new_potion
    end
  end

  describe "replace_potion/3" do
    test "replaces potion in occupied slot" do
      inventory = Inventory.new()
      old_potion = Potion.new(:minor, :healing)
      new_potion = Potion.new(:major, :healing)

      {:ok, inventory} = Inventory.add_potion(inventory, old_potion)
      {:ok, updated, returned_old} = Inventory.replace_potion(inventory, 0, new_potion)

      assert returned_old == old_potion
      assert Enum.at(updated.slots, 0) == new_potion
    end

    test "replaces potion in empty slot" do
      inventory = Inventory.new()
      new_potion = Potion.new(:major, :healing)

      {:ok, updated, old} = Inventory.replace_potion(inventory, 0, new_potion)

      assert old == nil
      assert Enum.at(updated.slots, 0) == new_potion
    end

    test "returns error for invalid slot index" do
      inventory = Inventory.new()
      potion = Potion.new(:minor, :healing)

      assert {:error, :invalid_slot} = Inventory.replace_potion(inventory, -1, potion)
      assert {:error, :invalid_slot} = Inventory.replace_potion(inventory, 5, potion)
    end
  end

  describe "get_potion/2" do
    test "returns potion from occupied slot" do
      inventory = Inventory.new()
      potion = Potion.new(:minor, :healing)
      {:ok, inventory} = Inventory.add_potion(inventory, potion)

      assert {:ok, ^potion} = Inventory.get_potion(inventory, 0)
    end

    test "returns error for empty slot" do
      inventory = Inventory.new()

      assert {:error, :empty_slot} = Inventory.get_potion(inventory, 0)
    end

    test "returns error for invalid slot index" do
      inventory = Inventory.new()

      assert {:error, :invalid_slot} = Inventory.get_potion(inventory, -1)
      assert {:error, :invalid_slot} = Inventory.get_potion(inventory, 5)
    end
  end

  describe "empty_slot_count/1" do
    test "returns 5 for empty inventory" do
      inventory = Inventory.new()
      assert Inventory.empty_slot_count(inventory) == 5
    end

    test "returns 4 for inventory with starter potion" do
      inventory = Inventory.new_with_starter()
      assert Inventory.empty_slot_count(inventory) == 4
    end

    test "returns 0 for full inventory" do
      inventory = Inventory.new()

      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))

      assert Inventory.empty_slot_count(inventory) == 0
    end

    test "decreases when adding potions" do
      inventory = Inventory.new()
      assert Inventory.empty_slot_count(inventory) == 5

      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      assert Inventory.empty_slot_count(inventory) == 4

      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      assert Inventory.empty_slot_count(inventory) == 3
    end
  end

  describe "full?/1" do
    test "returns false for empty inventory" do
      inventory = Inventory.new()
      refute Inventory.full?(inventory)
    end

    test "returns false for partially filled inventory" do
      inventory = Inventory.new()
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      refute Inventory.full?(inventory)
    end

    test "returns true for full inventory" do
      inventory = Inventory.new()

      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))
      {:ok, inventory} = Inventory.add_potion(inventory, Potion.new(:minor, :healing))

      assert Inventory.full?(inventory)
    end
  end

  describe "max_slots/0" do
    test "returns 5" do
      assert Inventory.max_slots() == 5
    end
  end
end
