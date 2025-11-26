defmodule SuperDungeonSlaughterEx.Game.Potion do
  @moduledoc """
  Potion entity with quality tiers and effect calculations.
  Supports healing and damage potions with visual customization.
  """

  @type quality :: :minor | :normal | :major
  @type category :: :healing | :damage
  @type flavor :: :fire | :acid | :lightning | :poison | :frost | :arcane | :shadow | :radiant

  @type t :: %__MODULE__{
          id: String.t(),
          quality: quality(),
          category: category(),
          flavor: flavor() | nil,
          display_name: String.t()
        }

  defstruct [:id, :quality, :category, :flavor, :display_name]

  @doc """
  Create a new potion with a unique ID and generated display name.
  Flavor is required for damage potions, ignored for healing potions.
  """
  @spec new(quality(), category(), flavor() | nil) :: t()
  def new(quality, category, flavor \\ nil) do
    id = generate_id()

    %__MODULE__{
      id: id,
      quality: quality,
      category: category,
      flavor: if(category == :damage, do: flavor, else: nil),
      display_name: generate_display_name(quality, category, flavor)
    }
  end

  @doc """
  Calculate the healing amount for a healing potion based on target's max HP.
  Returns the amount to heal (percentage of max HP, rounded down).
  """
  @spec calculate_healing(t(), pos_integer()) :: non_neg_integer()
  def calculate_healing(%{category: :healing, quality: quality}, max_hp) do
    percentage = get_percentage(quality)
    floor(max_hp * percentage)
  end

  def calculate_healing(%{category: :damage}, _max_hp), do: 0

  @doc """
  Calculate the damage amount for a damage potion based on target's current HP.
  Returns the amount of damage (percentage of current HP, rounded down).
  """
  @spec calculate_damage(t(), non_neg_integer()) :: non_neg_integer()
  def calculate_damage(%{category: :damage, quality: quality}, current_hp) do
    percentage = get_percentage(quality)
    floor(current_hp * percentage)
  end

  def calculate_damage(%{category: :healing}, _current_hp), do: 0

  @doc """
  Get the icon character for a potion based on quality.
  Minor = test tube, Normal = flask, Major = large container.
  """
  @spec get_icon(t()) :: String.t()
  def get_icon(%{quality: :minor}), do: "🧪"
  def get_icon(%{quality: :normal}), do: "⚗️"
  def get_icon(%{quality: :major}), do: "🏺"

  @doc """
  Get the Tailwind CSS size class for the potion icon.
  """
  @spec get_icon_size_class(t()) :: String.t()
  def get_icon_size_class(%{quality: :minor}), do: "text-sm"
  def get_icon_size_class(%{quality: :normal}), do: "text-base"
  def get_icon_size_class(%{quality: :major}), do: "text-xl"

  @doc """
  Get the Tailwind CSS color class for the potion.
  Healing potions are green-toned, damage potions vary by flavor.
  """
  @spec get_color_class(t()) :: String.t()
  def get_color_class(%{category: :healing, quality: :minor}), do: "text-green-300"
  def get_color_class(%{category: :healing, quality: :normal}), do: "text-green-400"
  def get_color_class(%{category: :healing, quality: :major}), do: "text-green-500"

  def get_color_class(%{category: :damage, flavor: :fire}), do: "text-orange-500"
  def get_color_class(%{category: :damage, flavor: :acid}), do: "text-lime-400"
  def get_color_class(%{category: :damage, flavor: :lightning}), do: "text-blue-400"
  def get_color_class(%{category: :damage, flavor: :poison}), do: "text-purple-500"
  def get_color_class(%{category: :damage, flavor: :frost}), do: "text-cyan-400"
  def get_color_class(%{category: :damage, flavor: :arcane}), do: "text-pink-500"
  def get_color_class(%{category: :damage, flavor: :shadow}), do: "text-gray-400"
  def get_color_class(%{category: :damage, flavor: :radiant}), do: "text-yellow-300"
  def get_color_class(%{category: :damage}), do: "text-red-500"

  @doc """
  Get the background color class for potion slots.
  """
  @spec get_bg_color_class(t()) :: String.t()
  def get_bg_color_class(%{category: :healing, quality: :minor}), do: "bg-green-900"
  def get_bg_color_class(%{category: :healing, quality: :normal}), do: "bg-green-800"
  def get_bg_color_class(%{category: :healing, quality: :major}), do: "bg-green-700"

  def get_bg_color_class(%{category: :damage, flavor: :fire}), do: "bg-orange-900"
  def get_bg_color_class(%{category: :damage, flavor: :acid}), do: "bg-lime-900"
  def get_bg_color_class(%{category: :damage, flavor: :lightning}), do: "bg-blue-900"
  def get_bg_color_class(%{category: :damage, flavor: :poison}), do: "bg-purple-900"
  def get_bg_color_class(%{category: :damage, flavor: :frost}), do: "bg-cyan-900"
  def get_bg_color_class(%{category: :damage, flavor: :arcane}), do: "bg-pink-900"
  def get_bg_color_class(%{category: :damage, flavor: :shadow}), do: "bg-gray-800"
  def get_bg_color_class(%{category: :damage, flavor: :radiant}), do: "bg-yellow-900"
  def get_bg_color_class(%{category: :damage}), do: "bg-red-900"

  @doc """
  Get the border color class for potion slots.
  """
  @spec get_border_color_class(t()) :: String.t()
  def get_border_color_class(%{category: :healing}), do: "border-green-500"

  def get_border_color_class(%{category: :damage, flavor: :fire}), do: "border-orange-500"
  def get_border_color_class(%{category: :damage, flavor: :acid}), do: "border-lime-500"
  def get_border_color_class(%{category: :damage, flavor: :lightning}), do: "border-blue-500"
  def get_border_color_class(%{category: :damage, flavor: :poison}), do: "border-purple-500"
  def get_border_color_class(%{category: :damage, flavor: :frost}), do: "border-cyan-500"
  def get_border_color_class(%{category: :damage, flavor: :arcane}), do: "border-pink-500"
  def get_border_color_class(%{category: :damage, flavor: :shadow}), do: "border-gray-500"
  def get_border_color_class(%{category: :damage, flavor: :radiant}), do: "border-yellow-500"
  def get_border_color_class(%{category: :damage}), do: "border-red-500"

  # Private Functions

  @spec generate_id() :: String.t()
  defp generate_id do
    # Generate a simple unique ID using timestamp + random number
    timestamp = System.system_time(:microsecond)
    random = :rand.uniform(1_000_000)
    "potion_#{timestamp}_#{random}"
  end

  @spec generate_display_name(quality(), category(), flavor() | nil) :: String.t()
  defp generate_display_name(quality, :healing, _flavor) do
    quality_text = quality_to_string(quality)
    "#{quality_text} Healing Potion"
  end

  defp generate_display_name(quality, :damage, flavor) when not is_nil(flavor) do
    quality_text = quality_to_string(quality)
    flavor_text = flavor_to_string(flavor)
    "#{quality_text} #{flavor_text} Potion"
  end

  defp generate_display_name(quality, :damage, _flavor) do
    quality_text = quality_to_string(quality)
    "#{quality_text} Damage Potion"
  end

  @spec quality_to_string(quality()) :: String.t()
  defp quality_to_string(:minor), do: "Minor"
  defp quality_to_string(:normal), do: "Normal"
  defp quality_to_string(:major), do: "Major"

  @spec flavor_to_string(flavor()) :: String.t()
  defp flavor_to_string(:fire), do: "Fire"
  defp flavor_to_string(:acid), do: "Acid"
  defp flavor_to_string(:lightning), do: "Lightning"
  defp flavor_to_string(:poison), do: "Poison"
  defp flavor_to_string(:frost), do: "Frost"
  defp flavor_to_string(:arcane), do: "Arcane"
  defp flavor_to_string(:shadow), do: "Shadow"
  defp flavor_to_string(:radiant), do: "Radiant"

  @spec get_percentage(quality()) :: float()
  defp get_percentage(:minor), do: 0.25
  defp get_percentage(:normal), do: 0.5
  defp get_percentage(:major), do: 1.0
end
