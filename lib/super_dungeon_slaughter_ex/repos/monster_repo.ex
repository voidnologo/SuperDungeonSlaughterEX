defmodule SuperDungeonSlaughterEx.Repos.MonsterRepo do
  @moduledoc """
  Repository for loading and managing monster templates from JSON.
  Provides level-based monster selection with fallback logic.
  """

  use GenServer
  alias SuperDungeonSlaughterEx.Game.Monster
  alias SuperDungeonSlaughterEx.Types

  @type state :: %{
          templates: %{String.t() => Monster.template()},
          level_index: %{integer() => [String.t()]}
        }

  # Client API

  @doc """
  Start the MonsterRepo GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    json_path = Keyword.get(opts, :json_path, default_json_path())
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, json_path, name: name)
  end

  @doc """
  Get a random monster appropriate for the given level (excludes bosses).
  """
  @spec get_monster_for_level(integer(), Types.difficulty()) :: Monster.t()
  def get_monster_for_level(level, difficulty \\ :normal) do
    GenServer.call(__MODULE__, {:get_monster, level, difficulty})
  end

  @doc """
  Get the boss monster for a specific level, if one exists.
  Returns {:ok, boss} or {:error, :no_boss_found}.
  """
  @spec get_boss_for_level(integer(), Types.difficulty()) ::
          {:ok, Monster.t()} | {:error, :no_boss_found}
  def get_boss_for_level(level, difficulty \\ :normal) do
    GenServer.call(__MODULE__, {:get_boss, level, difficulty})
  end

  @doc """
  Get all monster templates.
  """
  @spec get_all_templates() :: %{String.t() => Monster.template()}
  def get_all_templates do
    GenServer.call(__MODULE__, :get_all)
  end

  # Server Callbacks

  @impl true
  def init(json_path) do
    templates = load_monsters(json_path)
    level_index = build_level_index(templates)

    {:ok, %{templates: templates, level_index: level_index}}
  end

  @impl true
  def handle_call({:get_monster, level, difficulty}, _from, state) do
    available = find_monsters_for_level(level, state.level_index)
    # Filter out boss monsters from regular spawns
    regular_monsters = Enum.filter(available, fn name ->
      template = Map.get(state.templates, name)
      not Map.get(template, :is_boss, false)
    end)

    if Enum.empty?(regular_monsters) do
      {:reply, {:error, :no_monsters_available}, state}
    else
      monster_name = Enum.random(regular_monsters)
      template = Map.get(state.templates, monster_name)
      monster = Monster.from_template(template, difficulty)
      {:reply, monster, state}
    end
  end

  @impl true
  def handle_call({:get_boss, level, difficulty}, _from, state) do
    # Find boss monster for this exact level
    boss_template = Enum.find(state.templates, fn {_name, template} ->
      Map.get(template, :is_boss, false) and template.min_level == level
    end)

    case boss_template do
      {_name, template} ->
        boss = Monster.from_template(template, difficulty)
        {:reply, {:ok, boss}, state}
      nil ->
        {:reply, {:error, :no_boss_found}, state}
    end
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, state.templates, state}
  end

  # Private Functions

  defp default_json_path do
    Path.join([:code.priv_dir(:super_dungeon_slaughter_ex), "data", "monsters.json"])
  end

  defp load_monsters(json_path) do
    json_path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {name, data} ->
      template = %{
        name: name,
        min_level: data["min_level"],
        max_level: data["max_level"],
        avg_hp: data["avg_hp"],
        hp_sigma: data["hp_sigma"],
        damage_base: data["damage_base"],
        damage_sigma: data["damage_sigma"]
      }

      # Add optional boss fields if present
      template = if data["is_boss"], do: Map.put(template, :is_boss, true), else: template
      template = if data["floor"], do: Map.put(template, :floor, data["floor"]), else: template

      {name, template}
    end)
    |> Map.new()
  end

  defp build_level_index(templates) do
    Enum.reduce(templates, %{}, fn {name, template}, acc ->
      Enum.reduce(template.min_level..(template.max_level - 1), acc, fn level, level_acc ->
        Map.update(level_acc, level, [name], fn existing -> [name | existing] end)
      end)
    end)
  end

  defp find_monsters_for_level(level, level_index) do
    case Map.get(level_index, level) do
      nil -> find_fallback_monsters(level, level_index)
      monsters -> monsters
    end
  end

  defp find_fallback_monsters(_level, level_index) when map_size(level_index) == 0 do
    []
  end

  defp find_fallback_monsters(level, level_index) do
    closest_level =
      level_index
      |> Map.keys()
      |> Enum.min_by(fn lvl -> abs(lvl - level) end)

    Map.get(level_index, closest_level, [])
  end
end
