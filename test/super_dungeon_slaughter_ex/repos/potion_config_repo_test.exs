defmodule SuperDungeonSlaughterEx.Repos.PotionConfigRepoTest do
  use ExUnit.Case, async: true

  alias SuperDungeonSlaughterEx.Repos.PotionConfigRepo

  describe "get_drop_rates/0" do
    test "returns drop rate configuration" do
      rates = PotionConfigRepo.get_drop_rates()

      assert rates.minor == 0.05
      assert rates.normal == 0.03
      assert rates.major == 0.02
    end

    test "drop rates sum to 10%" do
      rates = PotionConfigRepo.get_drop_rates()
      total = rates.minor + rates.normal + rates.major

      assert_in_delta total, 0.10, 0.001
    end
  end

  describe "get_damage_flavors/0" do
    test "returns list of damage flavors" do
      flavors = PotionConfigRepo.get_damage_flavors()

      assert is_list(flavors)
      assert length(flavors) > 0
      assert :fire in flavors
      assert :acid in flavors
      assert :lightning in flavors
      assert :poison in flavors
      assert :frost in flavors
      assert :arcane in flavors
      assert :shadow in flavors
      assert :radiant in flavors
    end
  end

  describe "roll_for_drop/0" do
    test "returns either {:drop, quality} or :no_drop" do
      # Run multiple times to test randomness
      results =
        for _ <- 1..100 do
          PotionConfigRepo.roll_for_drop()
        end

      # Check that all results are valid
      for result <- results do
        assert result == :no_drop or
                 result == {:drop, :minor} or
                 result == {:drop, :normal} or
                 result == {:drop, :major}
      end
    end

    test "produces drops at approximately correct rate over many rolls" do
      # Run many trials to test probability distribution
      num_trials = 10_000

      results =
        for _ <- 1..num_trials do
          PotionConfigRepo.roll_for_drop()
        end

      drop_count = Enum.count(results, fn r -> r != :no_drop end)
      drop_rate = drop_count / num_trials

      # Should be approximately 10% (allow 2% margin for randomness)
      assert_in_delta drop_rate, 0.10, 0.02
    end

    test "produces quality distribution approximately matching configured rates" do
      num_trials = 10_000

      results =
        for _ <- 1..num_trials do
          PotionConfigRepo.roll_for_drop()
        end

      minor_count = Enum.count(results, fn r -> r == {:drop, :minor} end)
      normal_count = Enum.count(results, fn r -> r == {:drop, :normal} end)
      major_count = Enum.count(results, fn r -> r == {:drop, :major} end)

      minor_rate = minor_count / num_trials
      normal_rate = normal_count / num_trials
      major_rate = major_count / num_trials

      # Allow 2% margin for randomness
      assert_in_delta minor_rate, 0.05, 0.02
      assert_in_delta normal_rate, 0.03, 0.02
      assert_in_delta major_rate, 0.02, 0.02
    end
  end

  describe "generate_random_potion/1" do
    test "generates a potion with the specified quality" do
      minor = PotionConfigRepo.generate_random_potion(:minor)
      normal = PotionConfigRepo.generate_random_potion(:normal)
      major = PotionConfigRepo.generate_random_potion(:major)

      assert minor.quality == :minor
      assert normal.quality == :normal
      assert major.quality == :major
    end

    test "generates potions with random category" do
      # Generate many potions to check randomness
      potions =
        for _ <- 1..100 do
          PotionConfigRepo.generate_random_potion(:minor)
        end

      healing_count = Enum.count(potions, fn p -> p.category == :healing end)
      damage_count = Enum.count(potions, fn p -> p.category == :damage end)

      # Both categories should appear
      assert healing_count > 0
      assert damage_count > 0

      # Should be roughly 50/50 (allow wide margin due to small sample)
      assert healing_count + damage_count == 100
    end

    test "damage potions have a flavor assigned" do
      potions =
        for _ <- 1..50 do
          PotionConfigRepo.generate_random_potion(:minor)
        end

      damage_potions = Enum.filter(potions, fn p -> p.category == :damage end)

      # All damage potions should have a flavor
      for potion <- damage_potions do
        assert potion.flavor != nil
        assert potion.flavor in PotionConfigRepo.get_damage_flavors()
      end
    end

    test "healing potions have no flavor" do
      potions =
        for _ <- 1..50 do
          PotionConfigRepo.generate_random_potion(:minor)
        end

      healing_potions = Enum.filter(potions, fn p -> p.category == :healing end)

      # All healing potions should have nil flavor
      for potion <- healing_potions do
        assert potion.flavor == nil
      end
    end

    test "each generated potion has a unique ID" do
      potions =
        for _ <- 1..100 do
          PotionConfigRepo.generate_random_potion(:minor)
        end

      ids = Enum.map(potions, & &1.id)
      unique_ids = Enum.uniq(ids)

      assert length(ids) == length(unique_ids)
    end
  end
end
