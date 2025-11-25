defmodule SuperDungeonSlaughterEx.Game.Monster do
  @moduledoc """
  Monster entity with combat stats spawned from templates using Gaussian randomization.
  """

  @type template :: %{
          name: String.t(),
          min_level: non_neg_integer(),
          max_level: pos_integer(),
          avg_hp: float(),
          hp_sigma: float(),
          damage_base: float(),
          damage_sigma: float()
        }

  @type t :: %__MODULE__{
          name: String.t(),
          hp: non_neg_integer(),
          hp_max: pos_integer(),
          damage_base: float(),
          damage_sigma: float()
        }

  defstruct [:name, :hp, :hp_max, :damage_base, :damage_sigma]

  @doc """
  Create a monster instance from a template with randomized HP.
  """
  @spec from_template(template()) :: t()
  def from_template(template) do
    # Generate Gaussian-distributed HP
    hp = :rand.normal(template.avg_hp, template.hp_sigma)
    hp = max(1, round(hp))

    %__MODULE__{
      name: template.name,
      hp: hp,
      hp_max: hp,
      damage_base: template.damage_base,
      damage_sigma: template.damage_sigma
    }
  end

  @doc """
  Monster attacks, dealing Gaussian-distributed damage.
  Returns damage amount (non-negative).
  """
  @spec attack(t()) :: non_neg_integer()
  def attack(monster) do
    damage = :rand.normal(monster.damage_base, monster.damage_sigma)
    max(0, round(damage))
  end

  @doc """
  Monster takes damage.
  """
  @spec take_damage(t(), non_neg_integer()) :: t()
  def take_damage(monster, damage) do
    %{monster | hp: max(0, monster.hp - damage)}
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
  Check if monster is defeated (HP <= 0).
  """
  @spec defeated?(t()) :: boolean()
  def defeated?(%{hp: hp}), do: hp <= 0
end
