defmodule SuperDungeonSlaughterEx.ScoreTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Score

  describe "new/3" do
    test "creates a score with given values" do
      score = Score.new("Hero", 5, 20)

      assert score.name == "Hero"
      assert score.level == 5
      assert score.kills == 20
    end
  end

  describe "to_map/1" do
    test "converts score to map" do
      score = Score.new("TestHero", 10, 50)
      map = Score.to_map(score)

      assert map["name"] == "TestHero"
      assert map["level"] == 10
      assert map["kills"] == 50
    end

    test "produces map with string keys" do
      score = Score.new("Hero", 1, 1)
      map = Score.to_map(score)

      assert is_map(map)
      assert Map.has_key?(map, "name")
      assert Map.has_key?(map, "level")
      assert Map.has_key?(map, "kills")
    end
  end

  describe "from_map/1" do
    test "creates score from map" do
      map = %{"name" => "FromMap", "level" => 7, "kills" => 30}
      score = Score.from_map(map)

      assert score.name == "FromMap"
      assert score.level == 7
      assert score.kills == 30
    end

    test "round-trips with to_map" do
      original = Score.new("RoundTrip", 15, 100)
      map = Score.to_map(original)
      restored = Score.from_map(map)

      assert restored.name == original.name
      assert restored.level == original.level
      assert restored.kills == original.kills
    end
  end

  describe "compare/2" do
    test "higher level is greater" do
      score1 = Score.new("High", 10, 50)
      score2 = Score.new("Low", 5, 50)

      assert Score.compare(score1, score2) == :gt
      assert Score.compare(score2, score1) == :lt
    end

    test "same level, higher kills is greater" do
      score1 = Score.new("More", 5, 100)
      score2 = Score.new("Less", 5, 50)

      assert Score.compare(score1, score2) == :gt
      assert Score.compare(score2, score1) == :lt
    end

    test "same level and kills is equal" do
      score1 = Score.new("Same1", 5, 50)
      score2 = Score.new("Same2", 5, 50)

      assert Score.compare(score1, score2) == :eq
    end

    test "level takes precedence over kills" do
      score1 = Score.new("HighLevel", 10, 1)
      score2 = Score.new("LowLevel", 5, 999)

      assert Score.compare(score1, score2) == :gt
    end

    test "can be used with Enum.sort" do
      scores = [
        Score.new("Third", 5, 10),
        Score.new("First", 10, 50),
        Score.new("Second", 8, 30),
        Score.new("Fourth", 5, 5)
      ]

      sorted = Enum.sort(scores, fn s1, s2 -> Score.compare(s1, s2) != :lt end)

      assert Enum.at(sorted, 0).name == "First"
      assert Enum.at(sorted, 1).name == "Second"
      assert Enum.at(sorted, 2).name == "Third"
      assert Enum.at(sorted, 3).name == "Fourth"
    end
  end
end
