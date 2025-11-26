defmodule SuperDungeonSlaughterEx.Repos.PotionConfigRepo do
  @moduledoc """
  Configuration repository for potion types, drop rates, and properties.
  Designed to be extensible for future item types (weapons, armor).
  """

  alias SuperDungeonSlaughterEx.Game.Potion

  # Drop rate configuration (probabilities sum to 10%)
  @drop_rates %{
    minor: 0.05,
    normal: 0.03,
    major: 0.02
  }

  # Flavor options for damage potions
  @damage_flavors [:fire, :acid, :lightning, :poison, :frost, :arcane, :shadow, :radiant]

  @doc """
  Get the drop rate configuration map.
  """
  @spec get_drop_rates() :: %{atom() => float()}
  def get_drop_rates, do: @drop_rates

  @doc """
  Get the list of available damage potion flavors.
  """
  @spec get_damage_flavors() :: [Potion.flavor()]
  def get_damage_flavors, do: @damage_flavors

  @doc """
  Roll for a potion drop after killing a monster.
  Returns {:drop, quality} or :no_drop based on configured probabilities.

  Drop chances:
  - 5% for minor quality
  - 3% for normal quality
  - 2% for major quality
  - 90% no drop
  """
  @spec roll_for_drop() :: {:drop, Potion.quality()} | :no_drop
  def roll_for_drop do
    roll = :rand.uniform()

    cond do
      # Major: 0.00 to 0.02 (2%)
      roll < @drop_rates.major ->
        {:drop, :major}

      # Normal: 0.02 to 0.05 (3%)
      roll < @drop_rates.major + @drop_rates.normal ->
        {:drop, :normal}

      # Minor: 0.05 to 0.10 (5%)
      roll < @drop_rates.major + @drop_rates.normal + @drop_rates.minor ->
        {:drop, :minor}

      # No drop: 0.10 to 1.00 (90%)
      true ->
        :no_drop
    end
  end

  @doc """
  Generate a random potion with quality, category, and flavor.
  Used when a drop is confirmed via roll_for_drop/0.
  """
  @spec generate_random_potion(Potion.quality()) :: Potion.t()
  def generate_random_potion(quality) do
    category = random_category()
    flavor = if category == :damage, do: random_flavor(), else: nil

    Potion.new(quality, category, flavor)
  end

  # Private Functions

  @spec random_category() :: Potion.category()
  defp random_category do
    if :rand.uniform() < 0.5, do: :healing, else: :damage
  end

  @spec random_flavor() :: Potion.flavor()
  defp random_flavor do
    Enum.random(@damage_flavors)
  end
end
