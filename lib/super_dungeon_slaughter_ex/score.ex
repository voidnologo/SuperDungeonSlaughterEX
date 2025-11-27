defmodule SuperDungeonSlaughterEx.Score do
  @moduledoc """
  Immutable high score entry.
  """

  alias SuperDungeonSlaughterEx.Types

  @type t :: %__MODULE__{
          name: String.t(),
          level: pos_integer(),
          kills: non_neg_integer(),
          difficulty: Types.difficulty()
        }

  defstruct [:name, :level, :kills, difficulty: :normal]

  @doc """
  Create a new score.
  """
  @spec new(String.t(), pos_integer(), non_neg_integer(), Types.difficulty()) :: t()
  def new(name, level, kills, difficulty \\ :normal) do
    %__MODULE__{
      name: name,
      level: level,
      kills: kills,
      difficulty: difficulty
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
      "kills" => score.kills,
      "difficulty" => Atom.to_string(score.difficulty)
    }
  end

  @doc """
  Create score from map (JSON deserialization).
  """
  @spec from_map(map()) :: t()
  def from_map(map) do
    difficulty =
      case map["difficulty"] do
        "easy" -> :easy
        "hard" -> :hard
        _ -> :normal
      end

    %__MODULE__{
      name: map["name"],
      level: map["level"],
      kills: map["kills"],
      difficulty: difficulty
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
