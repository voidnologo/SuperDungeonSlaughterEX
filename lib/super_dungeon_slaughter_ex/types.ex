defmodule SuperDungeonSlaughterEx.Types do
  @moduledoc """
  Shared type definitions for Super Dungeon Slaughter EX.
  """

  @typedoc """
  Game difficulty levels affecting monster stats.
  - `:easy` - Monsters have 90-95% of normal stats
  - `:normal` - Standard difficulty (100% stats)
  - `:hard` - Monsters have 105-110% of normal stats
  """
  @type difficulty :: :easy | :normal | :hard
end
