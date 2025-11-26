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

  # Color configuration for all potion types and flavors
  @color_config %{
    {:healing, :minor} => %{
      text: "text-green-300",
      bg: "bg-green-900",
      border: "border-green-500"
    },
    {:healing, :normal} => %{
      text: "text-green-400",
      bg: "bg-green-800",
      border: "border-green-500"
    },
    {:healing, :major} => %{
      text: "text-green-500",
      bg: "bg-green-700",
      border: "border-green-500"
    },
    {:damage, :fire} => %{
      text: "text-orange-500",
      bg: "bg-orange-900",
      border: "border-orange-500"
    },
    {:damage, :acid} => %{
      text: "text-lime-400",
      bg: "bg-lime-900",
      border: "border-lime-500"
    },
    {:damage, :lightning} => %{
      text: "text-blue-400",
      bg: "bg-blue-900",
      border: "border-blue-500"
    },
    {:damage, :poison} => %{
      text: "text-purple-500",
      bg: "bg-purple-900",
      border: "border-purple-500"
    },
    {:damage, :frost} => %{
      text: "text-cyan-400",
      bg: "bg-cyan-900",
      border: "border-cyan-500"
    },
    {:damage, :arcane} => %{
      text: "text-pink-500",
      bg: "bg-pink-900",
      border: "border-pink-500"
    },
    {:damage, :shadow} => %{
      text: "text-gray-400",
      bg: "bg-gray-800",
      border: "border-gray-500"
    },
    {:damage, :radiant} => %{
      text: "text-yellow-300",
      bg: "bg-yellow-900",
      border: "border-yellow-500"
    },
    {:damage, :default} => %{
      text: "text-red-500",
      bg: "bg-red-900",
      border: "border-red-500"
    }
  }

  @doc """
  Get the Tailwind CSS color class for the potion.
  Healing potions are green-toned, damage potions vary by flavor.
  """
  @spec get_color_class(t()) :: String.t()
  def get_color_class(potion) do
    @color_config[potion_key(potion)].text
  end

  @doc """
  Get the background color class for potion slots.
  """
  @spec get_bg_color_class(t()) :: String.t()
  def get_bg_color_class(potion) do
    @color_config[potion_key(potion)].bg
  end

  @doc """
  Get the border color class for potion slots.
  """
  @spec get_border_color_class(t()) :: String.t()
  def get_border_color_class(potion) do
    @color_config[potion_key(potion)].border
  end

  # Private Functions

  @id_random_range 1_000_000

  @spec generate_id() :: String.t()
  defp generate_id do
    # Generate a simple unique ID using timestamp + random number
    timestamp = System.system_time(:microsecond)
    random = :rand.uniform(@id_random_range)
    "potion_#{timestamp}_#{random}"
  end

  @spec potion_key(t()) :: {category(), quality() | flavor()}
  defp potion_key(%{category: :healing, quality: quality}), do: {:healing, quality}

  defp potion_key(%{category: :damage, flavor: flavor}) when not is_nil(flavor),
    do: {:damage, flavor}

  defp potion_key(%{category: :damage}), do: {:damage, :default}

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
