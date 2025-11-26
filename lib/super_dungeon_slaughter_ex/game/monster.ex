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
          display_name: String.t(),
          hp: non_neg_integer(),
          hp_max: pos_integer(),
          damage_base: float(),
          damage_sigma: float()
        }

  defstruct [:name, :display_name, :hp, :hp_max, :damage_base, :damage_sigma]

  @doc """
  Create a monster instance from a template with randomized HP.
  """
  @spec from_template(template()) :: t()
  def from_template(template) do
    # Generate Gaussian-distributed HP
    hp = :rand.normal(template.avg_hp, template.hp_sigma)
    hp = max(1, round(hp))

    # Calculate descriptors based on z-scores
    hp_descriptor = get_hp_descriptor(hp, template.avg_hp, template.hp_sigma)
    damage_descriptor = get_damage_descriptor(template.damage_base, template.damage_sigma)

    # Build display name with descriptors
    display_name = "#{hp_descriptor} #{damage_descriptor} #{template.name}"

    %__MODULE__{
      name: template.name,
      display_name: display_name,
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

  # Private helper functions for descriptors

  # Descriptor word lists for each category
  @hp_descriptors_low ["Frail", "Weak", "Sickly", "Fragile", "Feeble"]
  @hp_descriptors_mid ["Average", "Normal", "Typical", "Standard", "Ordinary"]
  @hp_descriptors_high ["Robust", "Sturdy", "Hardy", "Tough", "Resilient"]

  @damage_descriptors_low ["Timid", "Weak", "Harmless", "Gentle", "Docile"]
  @damage_descriptors_mid ["Capable", "Moderate", "Competent", "Trained", "Skilled"]
  @damage_descriptors_high ["Vicious", "Fierce", "Brutal", "Savage", "Deadly"]

  # Z-score thresholds for percentile buckets
  # -0.43 SD ≈ 33rd percentile, +0.43 SD ≈ 67th percentile
  @lower_threshold -0.43
  @upper_threshold 0.43

  @spec get_hp_descriptor(number(), float(), float()) :: String.t()
  defp get_hp_descriptor(hp, avg_hp, hp_sigma) when hp_sigma > 0 do
    z_score = (hp - avg_hp) / hp_sigma
    select_descriptor(z_score, @hp_descriptors_low, @hp_descriptors_mid, @hp_descriptors_high)
  end

  defp get_hp_descriptor(_hp, _avg_hp, _hp_sigma) do
    Enum.random(@hp_descriptors_mid)
  end

  @spec get_damage_descriptor(float(), float()) :: String.t()
  defp get_damage_descriptor(damage_base, damage_sigma) when damage_sigma > 0 do
    # Sample a damage value to determine category
    sample_damage = :rand.normal(damage_base, damage_sigma)
    z_score = (sample_damage - damage_base) / damage_sigma

    select_descriptor(
      z_score,
      @damage_descriptors_low,
      @damage_descriptors_mid,
      @damage_descriptors_high
    )
  end

  defp get_damage_descriptor(_damage_base, _damage_sigma) do
    Enum.random(@damage_descriptors_mid)
  end

  @spec select_descriptor(float(), [String.t()], [String.t()], [String.t()]) :: String.t()
  defp select_descriptor(z_score, low_list, mid_list, high_list) do
    cond do
      z_score < @lower_threshold -> Enum.random(low_list)
      z_score > @upper_threshold -> Enum.random(high_list)
      true -> Enum.random(mid_list)
    end
  end
end
