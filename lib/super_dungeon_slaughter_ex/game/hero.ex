defmodule SuperDungeonSlaughterEx.Game.Hero do
  @moduledoc """
  Player character with combat stats, progression system, and game statistics tracking.
  """

  alias SuperDungeonSlaughterEx.Game.Inventory

  @type t :: %__MODULE__{
          name: String.t(),
          level: pos_integer(),
          hp: non_neg_integer(),
          hp_max: pos_integer(),
          total_kills: non_neg_integer(),
          level_kills: non_neg_integer(),
          damage_min: non_neg_integer(),
          damage_max: non_neg_integer(),
          heal_min: pos_integer(),
          heal_max: pos_integer(),
          # Game statistics
          total_damage_dealt: non_neg_integer(),
          total_health_healed: non_neg_integer(),
          monsters_killed_by_type: %{String.t() => non_neg_integer()},
          # Inventory
          inventory: Inventory.t(),
          # Floor progression
          bosses_defeated: non_neg_integer(),
          current_floor: non_neg_integer()
        }

  defstruct name: "",
            level: 1,
            hp: 10,
            hp_max: 10,
            total_kills: 0,
            level_kills: 0,
            damage_min: 0,
            damage_max: 3,
            heal_min: 1,
            heal_max: 4,
            total_damage_dealt: 0,
            total_health_healed: 0,
            monsters_killed_by_type: %{},
            inventory: nil,
            bosses_defeated: 0,
            current_floor: 0

  @doc """
  Create a new level 1 hero with starting stats and inventory with starter potion.
  """
  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{
      name: name,
      inventory: Inventory.new_with_starter()
    }
  end

  @doc """
  Hero attacks a monster, dealing random damage within range.
  Returns {updated_hero, damage_dealt}.
  """
  @spec attack(t()) :: {t(), non_neg_integer()}
  def attack(hero) do
    damage = :rand.uniform(hero.damage_max - hero.damage_min + 1) + hero.damage_min - 1
    updated_hero = %{hero | total_damage_dealt: hero.total_damage_dealt + damage}
    {updated_hero, damage}
  end

  @doc """
  Hero takes damage.
  """
  @spec take_damage(t(), non_neg_integer()) :: t()
  def take_damage(hero, damage) do
    %{hero | hp: max(0, hero.hp - damage)}
  end

  @doc """
  Hero rests and heals random amount within healing range.
  Returns {updated_hero, heal_amount}.
  """
  @spec rest(t()) :: {t(), non_neg_integer()}
  def rest(hero) do
    heal = :rand.uniform(hero.heal_max - hero.heal_min + 1) + hero.heal_min - 1
    new_hp = min(hero.hp_max, hero.hp + heal)
    actual_heal = new_hp - hero.hp

    updated_hero = %{
      hero
      | hp: new_hp,
        total_health_healed: hero.total_health_healed + actual_heal
    }

    {updated_hero, actual_heal}
  end

  @doc """
  Record a monster kill, incrementing counters and tracking by monster type.
  """
  @spec record_kill(t(), String.t()) :: t()
  def record_kill(hero, monster_name) do
    current_count = Map.get(hero.monsters_killed_by_type, monster_name, 0)

    %{
      hero
      | total_kills: hero.total_kills + 1,
        level_kills: hero.level_kills + 1,
        monsters_killed_by_type:
          Map.put(hero.monsters_killed_by_type, monster_name, current_count + 1)
    }
  end

  @doc """
  Level up the hero if kill threshold is met.
  """
  @spec level_up(t()) :: t()
  def level_up(hero) do
    if should_level_up?(hero) do
      %{
        hero
        | level: hero.level + 1,
          hp_max: hero.hp_max + hero.level + 1,
          level_kills: 0,
          damage_min: scale_stat(hero.damage_min, 0.1),
          damage_max: scale_stat(hero.damage_max, 0.1),
          heal_min: scale_stat(hero.heal_min, 0.15),
          heal_max: scale_stat(hero.heal_max, 0.15)
      }
    else
      hero
    end
  end

  @doc """
  Check if hero should level up (when level_kills equals current level).
  """
  @spec should_level_up?(t()) :: boolean()
  def should_level_up?(hero) do
    hero.level_kills > 0 and rem(hero.level_kills, hero.level) == 0
  end

  @doc """
  Calculate HP percentage for color coding (0.0 to 1.0).
  """
  @spec hp_percentage(t()) :: float()
  def hp_percentage(%{hp: hp, hp_max: max}) when max > 0 do
    hp / max
  end

  def hp_percentage(_), do: 0.0

  @doc """
  Check if hero is defeated (HP <= 0).
  """
  @spec defeated?(t()) :: boolean()
  def defeated?(%{hp: hp}), do: hp <= 0

  @doc """
  Get formatted statistics for game over screen.
  """
  @spec get_statistics(t()) :: %{
          level: pos_integer(),
          kills: non_neg_integer(),
          damage_dealt: non_neg_integer(),
          health_healed: non_neg_integer(),
          monster_breakdown: [{String.t(), non_neg_integer()}]
        }
  def get_statistics(hero) do
    %{
      level: hero.level,
      kills: hero.total_kills,
      damage_dealt: hero.total_damage_dealt,
      health_healed: hero.total_health_healed,
      monster_breakdown:
        hero.monsters_killed_by_type |> Enum.sort_by(fn {_, count} -> count end, :desc)
    }
  end

  @doc """
  Use a healing potion from inventory, healing the hero.
  Returns {:ok, updated_hero, heal_amount} or {:error, reason}.
  """
  @spec use_healing_potion(t(), non_neg_integer()) ::
          {:ok, t(), non_neg_integer()} | {:error, atom()}
  def use_healing_potion(hero, slot_index) do
    alias SuperDungeonSlaughterEx.Game.Potion

    case Inventory.get_potion(hero.inventory, slot_index) do
      {:ok, potion} when potion.category == :healing ->
        # Calculate healing amount
        heal_amount = Potion.calculate_healing(potion, hero.hp_max)
        new_hp = min(hero.hp_max, hero.hp + heal_amount)
        actual_heal = new_hp - hero.hp

        # Remove potion from inventory
        {:ok, updated_inventory, _removed_potion} =
          Inventory.remove_potion(hero.inventory, slot_index)

        updated_hero = %{
          hero
          | hp: new_hp,
            total_health_healed: hero.total_health_healed + actual_heal,
            inventory: updated_inventory
        }

        {:ok, updated_hero, actual_heal}

      {:ok, _non_healing_potion} ->
        {:error, :not_healing_potion}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Add a potion to the hero's inventory.
  Returns {:ok, updated_hero} or {:full, hero}.
  """
  @spec add_potion_to_inventory(t(), SuperDungeonSlaughterEx.Game.Potion.t()) ::
          {:ok, t()} | {:full, t()}
  def add_potion_to_inventory(hero, potion) do
    case Inventory.add_potion(hero.inventory, potion) do
      {:ok, updated_inventory} ->
        {:ok, %{hero | inventory: updated_inventory}}

      {:full, _inventory} ->
        {:full, hero}
    end
  end

  @doc """
  Replace a potion in the hero's inventory.
  Returns {:ok, updated_hero, old_potion}.
  """
  @spec replace_potion_in_inventory(
          t(),
          non_neg_integer(),
          SuperDungeonSlaughterEx.Game.Potion.t()
        ) ::
          {:ok, t(), SuperDungeonSlaughterEx.Game.Potion.t() | nil} | {:error, atom()}
  def replace_potion_in_inventory(hero, slot_index, new_potion) do
    case Inventory.replace_potion(hero.inventory, slot_index, new_potion) do
      {:ok, updated_inventory, old_potion} ->
        {:ok, %{hero | inventory: updated_inventory}, old_potion}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Use a damage potion on a monster, removing it from inventory.
  Returns {:ok, updated_hero, damage_amount} or {:error, reason}.
  The damage calculation is done separately when applying to monster.
  """
  @spec use_damage_potion(t(), non_neg_integer()) ::
          {:ok, t(), SuperDungeonSlaughterEx.Game.Potion.t()} | {:error, atom()}
  def use_damage_potion(hero, slot_index) do
    case Inventory.get_potion(hero.inventory, slot_index) do
      {:ok, potion} when potion.category == :damage ->
        # Remove potion from inventory
        {:ok, updated_inventory, _removed_potion} =
          Inventory.remove_potion(hero.inventory, slot_index)

        updated_hero = %{hero | inventory: updated_inventory}
        {:ok, updated_hero, potion}

      {:ok, _non_damage_potion} ->
        {:error, :not_damage_potion}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Functions

  @spec scale_stat(integer(), float()) :: integer()
  defp scale_stat(0, _multiplier), do: 1

  defp scale_stat(current, multiplier) do
    (current * (1 + multiplier))
    |> ceil()
    |> round()
  end
end
