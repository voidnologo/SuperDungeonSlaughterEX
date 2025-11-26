defmodule SuperDungeonSlaughterEx.Repos.ScoreRepoSimpleTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Repos.ScoreRepo
  alias SuperDungeonSlaughterEx.Score

  setup do
    # Create unique path and name for each test
    test_path = Path.join([System.tmp_dir!(), "test_scores_#{:rand.uniform(999_999_999)}.json"])
    test_name = :"test_score_repo_#{:rand.uniform(999_999_999)}"

    # Start with empty scores file
    File.write!(test_path, "[]")

    # Start the repo with test data and unique name
    {:ok, _pid} = start_supervised({ScoreRepo, json_path: test_path, name: test_name})

    on_exit(fn ->
      File.rm(test_path)
    end)

    {:ok, test_path: test_path, repo_name: test_name}
  end

  test "adds and retrieves a single score", %{repo_name: repo_name} do
    score = Score.new("Hero1", 5, 20)
    :ok = GenServer.cast(repo_name, {:add, score})

    Process.sleep(10)

    scores = GenServer.call(repo_name, {:get_top, 10})

    assert length(scores) == 1
    assert hd(scores).name == "Hero1"
  end

  test "sorts scores by level then kills", %{repo_name: repo_name} do
    GenServer.cast(repo_name, {:add, Score.new("Third", 5, 20)})
    GenServer.cast(repo_name, {:add, Score.new("First", 10, 50)})
    GenServer.cast(repo_name, {:add, Score.new("Second", 8, 30)})

    Process.sleep(50)

    scores = GenServer.call(repo_name, {:get_top, 10})

    assert Enum.at(scores, 0).name == "First"
    assert Enum.at(scores, 1).name == "Second"
    assert Enum.at(scores, 2).name == "Third"
  end

  test "persists scores to JSON file", %{repo_name: repo_name, test_path: test_path} do
    score = Score.new("Persistent", 7, 35)
    GenServer.cast(repo_name, {:add, score})

    Process.sleep(100)

    {:ok, content} = File.read(test_path)
    data = Jason.decode!(content)

    assert length(data) == 1
    assert hd(data)["name"] == "Persistent"
  end
end
