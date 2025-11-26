defmodule SuperDungeonSlaughterEx.Repos.MonsterRepoSimpleTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Repos.MonsterRepo
  alias SuperDungeonSlaughterEx.Game.Monster

  setup do
    # Create unique paths and names for each test
    test_path = Path.join([System.tmp_dir!(), "test_monsters_#{:rand.uniform(999_999_999)}.json"])
    test_name = :"test_monster_repo_#{:rand.uniform(999_999_999)}"

    # Create test monsters JSON
    test_data = %{
      "Kobold" => %{
        "min_level" => 0,
        "max_level" => 4,
        "avg_hp" => 5.0,
        "hp_sigma" => 1.0,
        "damage_base" => 2.0,
        "damage_sigma" => 0.5
      },
      "Goblin" => %{
        "min_level" => 1,
        "max_level" => 5,
        "avg_hp" => 8.0,
        "hp_sigma" => 2.0,
        "damage_base" => 3.0,
        "damage_sigma" => 1.0
      },
      "Orc" => %{
        "min_level" => 3,
        "max_level" => 8,
        "avg_hp" => 15.0,
        "hp_sigma" => 3.0,
        "damage_base" => 5.0,
        "damage_sigma" => 2.0
      }
    }

    File.write!(test_path, Jason.encode!(test_data))

    # Start the repo with test data and unique name
    start_supervised!({MonsterRepo, json_path: test_path, name: test_name})

    on_exit(fn ->
      File.rm(test_path)
    end)

    {:ok, repo_name: test_name}
  end

  test "returns a monster for level 0", %{repo_name: repo_name} do
    monster = GenServer.call(repo_name, {:get_monster, 0})

    assert %Monster{} = monster
    assert monster.name == "Kobold"
  end

  test "returns appropriate monster for level 1", %{repo_name: repo_name} do
    monster = GenServer.call(repo_name, {:get_monster, 1})

    assert %Monster{} = monster
    assert monster.name in ["Kobold", "Goblin"]
  end

  test "returns monster with valid HP", %{repo_name: repo_name} do
    monster = GenServer.call(repo_name, {:get_monster, 1})

    assert monster.hp > 0
    assert monster.hp_max > 0
    assert monster.hp == monster.hp_max
  end

  test "returns all templates", %{repo_name: repo_name} do
    templates = GenServer.call(repo_name, :get_all)

    assert is_map(templates)
    assert Map.has_key?(templates, "Kobold")
    assert Map.has_key?(templates, "Goblin")
    assert Map.has_key?(templates, "Orc")
  end
end
