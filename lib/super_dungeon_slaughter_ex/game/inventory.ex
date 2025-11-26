defmodule SuperDungeonSlaughterEx.Game.Inventory do
  @moduledoc """
  Inventory system for managing potion storage.
  Fixed 5-slot capacity to encourage strategic potion usage.
  """

  alias SuperDungeonSlaughterEx.Game.Potion

  @max_slots 5

  @type t :: %__MODULE__{
          slots: [Potion.t() | nil]
        }

  defstruct slots: [nil, nil, nil, nil, nil]

  @doc """
  Create a new empty inventory with 5 slots.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Create a new inventory with a starter Normal Healing Potion in the first slot.
  """
  @spec new_with_starter() :: t()
  def new_with_starter do
    starter_potion = Potion.new(:normal, :healing)
    %__MODULE__{slots: [starter_potion, nil, nil, nil, nil]}
  end

  @doc """
  Add a potion to the first available empty slot.
  Returns {:ok, updated_inventory} or {:full, inventory} if all slots are occupied.
  """
  @spec add_potion(t(), Potion.t()) :: {:ok, t()} | {:full, t()}
  def add_potion(inventory, potion) do
    case find_empty_slot_index(inventory) do
      nil ->
        {:full, inventory}

      index ->
        updated_slots = List.replace_at(inventory.slots, index, potion)
        {:ok, %{inventory | slots: updated_slots}}
    end
  end

  @doc """
  Remove a potion from the specified slot index (0-4).
  Returns {:ok, updated_inventory, removed_potion} or {:error, :invalid_slot}.
  """
  @spec remove_potion(t(), non_neg_integer()) ::
          {:ok, t(), Potion.t()} | {:error, :invalid_slot | :empty_slot}
  def remove_potion(inventory, slot_index) when slot_index >= 0 and slot_index < @max_slots do
    case Enum.at(inventory.slots, slot_index) do
      nil ->
        {:error, :empty_slot}

      potion ->
        updated_slots = List.replace_at(inventory.slots, slot_index, nil)
        {:ok, %{inventory | slots: updated_slots}, potion}
    end
  end

  def remove_potion(_inventory, _slot_index), do: {:error, :invalid_slot}

  @doc """
  Replace a potion at the specified slot with a new potion.
  Returns {:ok, updated_inventory, old_potion} or {:error, reason}.
  """
  @spec replace_potion(t(), non_neg_integer(), Potion.t()) ::
          {:ok, t(), Potion.t() | nil} | {:error, :invalid_slot}
  def replace_potion(inventory, slot_index, new_potion)
      when slot_index >= 0 and slot_index < @max_slots do
    old_potion = Enum.at(inventory.slots, slot_index)
    updated_slots = List.replace_at(inventory.slots, slot_index, new_potion)
    {:ok, %{inventory | slots: updated_slots}, old_potion}
  end

  def replace_potion(_inventory, _slot_index, _new_potion), do: {:error, :invalid_slot}

  @doc """
  Get the potion at the specified slot index.
  Returns {:ok, potion} or {:error, reason}.
  """
  @spec get_potion(t(), non_neg_integer()) ::
          {:ok, Potion.t()} | {:error, :invalid_slot | :empty_slot}
  def get_potion(inventory, slot_index) when slot_index >= 0 and slot_index < @max_slots do
    case Enum.at(inventory.slots, slot_index) do
      nil -> {:error, :empty_slot}
      potion -> {:ok, potion}
    end
  end

  def get_potion(_inventory, _slot_index), do: {:error, :invalid_slot}

  @doc """
  Count the number of empty slots in the inventory.
  """
  @spec empty_slot_count(t()) :: non_neg_integer()
  def empty_slot_count(inventory) do
    Enum.count(inventory.slots, &is_nil/1)
  end

  @doc """
  Check if the inventory is full (all slots occupied).
  """
  @spec full?(t()) :: boolean()
  def full?(inventory) do
    empty_slot_count(inventory) == 0
  end

  @doc """
  Get the maximum number of inventory slots.
  """
  @spec max_slots() :: pos_integer()
  def max_slots, do: @max_slots

  # Private Functions

  @spec find_empty_slot_index(t()) :: non_neg_integer() | nil
  defp find_empty_slot_index(inventory) do
    inventory.slots
    |> Enum.with_index()
    |> Enum.find_value(fn {slot, index} ->
      if is_nil(slot), do: index
    end)
  end
end
