defmodule SuperDungeonSlaughterEx.Game.HistoryEntry do
  @moduledoc """
  Structured history entry with message, event type, icon, and color coding.
  Makes game history more readable and celebratory.
  """

  @type t :: %__MODULE__{
          message: String.t(),
          type: type(),
          icon: String.t()
        }

  @type type ::
          :combat
          | :healing
          | :victory
          | :item
          | :level_up
          | :death
          | :system
          | :boss_encounter
          | :boss_victory

  defstruct [:message, :type, :icon]

  @doc """
  Create a new history entry with appropriate icon for the event type.
  """
  @spec new(String.t(), type()) :: t()
  def new(message, type) do
    %__MODULE__{
      message: message,
      type: type,
      icon: get_icon(type)
    }
  end

  @doc """
  Get the icon emoji for a given event type.
  """
  @spec get_icon(type()) :: String.t()
  def get_icon(:combat), do: "🗡️"
  def get_icon(:healing), do: "❤️"
  def get_icon(:victory), do: "⭐"
  def get_icon(:item), do: "🎁"
  def get_icon(:level_up), do: "🎉"
  def get_icon(:death), do: "💀"
  def get_icon(:system), do: "📢"
  def get_icon(:boss_encounter), do: "⚔️"
  def get_icon(:boss_victory), do: "🏆"

  @doc """
  Get the Tailwind CSS color class for a given event type.
  """
  @spec get_color_class(type()) :: String.t()
  def get_color_class(:combat), do: "text-green-300"
  def get_color_class(:healing), do: "text-green-400"
  def get_color_class(:victory), do: "text-yellow-300"
  def get_color_class(:item), do: "text-purple-400"
  def get_color_class(:level_up), do: "text-cyan-400"
  def get_color_class(:death), do: "text-red-400"
  def get_color_class(:system), do: "text-gray-400"
  def get_color_class(:boss_encounter), do: "text-red-500"
  def get_color_class(:boss_victory), do: "text-yellow-400"

  @doc """
  Create a visual separator line for major events like level ups.
  """
  @spec separator(type()) :: t()
  def separator(type \\ :level_up) do
    new("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type)
  end
end
