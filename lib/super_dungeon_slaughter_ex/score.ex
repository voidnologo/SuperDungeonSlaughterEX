defmodule SuperDungeonSlaughterEx.Score do
  @moduledoc """
  Immutable high score entry.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          level: pos_integer(),
          kills: non_neg_integer()
        }

  defstruct [:name, :level, :kills]

  @doc """
  Create a new score.
  """
  @spec new(String.t(), pos_integer(), non_neg_integer()) :: t()
  def new(name, level, kills) do
    %__MODULE__{
      name: name,
      level: level,
      kills: kills
    }
  end

  @doc """
  Convert score to map for JSON serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(score) do
    %{
      "name" => score.name,
      "level" => score.level,
      "kills" => score.kills
    }
  end

  @doc """
  Create score from map (JSON deserialization).
  """
  @spec from_map(map()) :: t()
  def from_map(map) do
    %__MODULE__{
      name: map["name"],
      level: map["level"],
      kills: map["kills"]
    }
  end

  @doc """
  Compare two scores for sorting.
  Primary: level (descending), Secondary: kills (descending).
  """
  @spec compare(t(), t()) :: :lt | :eq | :gt
  def compare(score1, score2) do
    cond do
      score1.level > score2.level -> :gt
      score1.level < score2.level -> :lt
      score1.kills > score2.kills -> :gt
      score1.kills < score2.kills -> :lt
      true -> :eq
    end
  end
end
