defmodule SuperDungeonSlaughterEx.Repos.ScoreRepo do
  @moduledoc """
  Repository for managing high scores with JSON file persistence.
  Maintains sorted in-memory list and provides thread-safe access.
  """

  use GenServer
  alias SuperDungeonSlaughterEx.Score

  @type state :: %{
          scores: [Score.t()],
          json_path: String.t()
        }

  # Client API

  @doc """
  Start the ScoreRepo GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    json_path = Keyword.get(opts, :json_path, default_json_path())
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, json_path, name: name)
  end

  @doc """
  Add a new score and persist to disk.
  """
  @spec add_score(Score.t()) :: :ok
  def add_score(score) do
    GenServer.cast(__MODULE__, {:add, score})
  end

  @doc """
  Get top N scores (default 10).
  """
  @spec get_top_scores(pos_integer()) :: [Score.t()]
  def get_top_scores(limit \\ 10) do
    GenServer.call(__MODULE__, {:get_top, limit})
  end

  # Server Callbacks

  @impl true
  def init(json_path) do
    scores = load_scores(json_path)
    {:ok, %{scores: scores, json_path: json_path}}
  end

  @impl true
  def handle_cast({:add, score}, state) do
    scores = [score | state.scores] |> sort_scores()
    save_scores(scores, state.json_path)
    {:noreply, %{state | scores: scores}}
  end

  @impl true
  def handle_call({:get_top, limit}, _from, state) do
    top_scores = Enum.take(state.scores, limit)
    {:reply, top_scores, state}
  end

  # Private Functions

  defp default_json_path do
    Path.join([:code.priv_dir(:super_dungeon_slaughter_ex), "data", "scores.json"])
  end

  defp load_scores(json_path) do
    case File.read(json_path) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Enum.map(&Score.from_map/1)
        |> sort_scores()

      {:error, :enoent} ->
        []
    end
  end

  defp save_scores(scores, json_path) do
    scores_json =
      scores
      |> Enum.map(&Score.to_map/1)
      |> Jason.encode!(pretty: true)

    File.write!(json_path, scores_json)
  end

  defp sort_scores(scores) do
    Enum.sort(scores, fn s1, s2 ->
      Score.compare(s1, s2) != :lt
    end)
  end
end
