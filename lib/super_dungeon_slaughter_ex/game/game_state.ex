defmodule SuperDungeonSlaughterEx.Game.GameState do
  @moduledoc """
  Main game state container managing hero, monster, combat history, and game over status.
  """

  alias SuperDungeonSlaughterEx.Game.{Hero, Monster, HistoryEntry, Potion, Inventory}
  alias SuperDungeonSlaughterEx.Repos.{MonsterRepo, PotionConfigRepo}
  alias SuperDungeonSlaughterEx.Types

  @max_history 200

  @type t :: %__MODULE__{
          hero: Hero.t(),
          monster: Monster.t(),
          history: [HistoryEntry.t()],
          game_over: boolean(),
          difficulty: Types.difficulty(),
          pending_potion_drop: Potion.t() | nil,
          show_potion_pickup_modal: boolean(),
          show_potion_use_modal: boolean(),
          selected_potion_slot: non_neg_integer() | nil,
          selected_potion: Potion.t() | nil,
          pending_boss_reward: boolean()
        }

  defstruct [
    :hero,
    :monster,
    history: [],
    game_over: false,
    difficulty: :normal,
    pending_potion_drop: nil,
    show_potion_pickup_modal: false,
    show_potion_use_modal: false,
    selected_potion_slot: nil,
    selected_potion: nil,
    pending_boss_reward: false
  ]

  @doc """
  Create a new game state with a hero and first monster.
  """
  @spec new(String.t(), Types.difficulty()) :: t()
  def new(hero_name, difficulty \\ :normal) do
    hero = Hero.new(hero_name)
    monster = MonsterRepo.get_monster_for_level(hero.level, difficulty)

    %__MODULE__{
      hero: hero,
      monster: monster,
      difficulty: difficulty,
      history: [
        HistoryEntry.new("A wild #{monster.display_name} appears!", :system),
        HistoryEntry.new("Welcome, #{hero_name}!", :system)
      ]
    }
  end

  @doc """
  Handle fight action: hero attacks, monster counter-attacks if alive, check for kills/death.
  """
  @spec handle_fight(t()) :: t()
  def handle_fight(state) do
    # Hero attacks
    {updated_hero, damage} = Hero.attack(state.hero)
    updated_monster = Monster.take_damage(state.monster, damage)

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> Map.put(:monster, updated_monster)
      |> add_to_history(
        "#{updated_hero.name} deals #{damage} damage to the #{updated_monster.display_name}!",
        :combat
      )

    # Check if monster defeated
    if Monster.defeated?(updated_monster) do
      handle_monster_death(state)
    else
      # Monster counter-attacks
      handle_monster_attack(state)
    end
  end

  @doc """
  Handle rest action: hero heals, monster attacks, check for death.
  """
  @spec handle_rest(t()) :: t()
  def handle_rest(state) do
    # Hero rests
    {updated_hero, heal} = Hero.rest(state.hero)

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history("#{updated_hero.name} heals #{heal} HP!", :healing)

    # Monster attacks
    handle_monster_attack(state)
  end

  @doc """
  Add a message to the history with event type (newest first), limiting total history size.
  """
  @spec add_to_history(t(), String.t(), HistoryEntry.type()) :: t()
  def add_to_history(state, message, type \\ :system) do
    entry = HistoryEntry.new(message, type)
    history = [entry | state.history] |> Enum.take(@max_history)
    %{state | history: history}
  end

  # Private Functions

  defp handle_monster_attack(state) do
    damage = Monster.attack(state.monster)
    updated_hero = Hero.take_damage(state.hero, damage)

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history(
        "#{state.monster.display_name} deals #{damage} damage to #{updated_hero.name}!",
        :combat
      )

    # Check if hero defeated
    if Hero.defeated?(updated_hero) do
      state
      |> Map.put(:game_over, true)
      |> add_to_history(
        "You died! You managed to kill #{updated_hero.total_kills} monsters.",
        :death
      )
    else
      state
    end
  end

  defp handle_monster_death(state) do
    is_boss = Monster.is_boss?(state.monster)

    # Record the kill (use base name for stats tracking)
    updated_hero = Hero.record_kill(state.hero, state.monster.name)

    # If boss was defeated, also increment boss counter
    updated_hero = if is_boss do
      %{updated_hero | bosses_defeated: updated_hero.bosses_defeated + 1}
    else
      updated_hero
    end

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history(
        "Congratulations! You killed the #{state.monster.display_name}!",
        :victory
      )
      |> add_to_history("You have killed #{updated_hero.total_kills} monsters.", :victory)

    if is_boss do
      # Boss defeated - heal to full, update floor, set pending reward
      floor = state.monster.floor
      healed_hero = %{updated_hero | hp: updated_hero.hp_max, current_floor: floor}

      state
      |> Map.put(:hero, healed_hero)
      |> Map.put(:pending_boss_reward, true)
      |> add_separator(:boss_victory)
      |> add_to_history("🏆 FLOOR #{floor} BOSS DEFEATED! 🏆", :boss_victory)
      |> add_to_history("Your wounds heal as you rest.", :healing)
      |> add_to_history("HP fully restored!", :healing)
      |> add_separator(:boss_victory)
    else
      # Regular monster - check for potion drop, level up, spawn next monster
      state = handle_potion_drop(state)
      state = check_level_up(state)
      spawn_next_monster(state)
    end
  end

  defp spawn_next_monster(state) do
    # Check if we should spawn a boss at the current level
    case should_spawn_boss?(state.hero.level) do
      true ->
        case MonsterRepo.get_boss_for_level(state.hero.level, state.difficulty) do
          {:ok, boss} ->
            floor = boss.floor

            state
            |> Map.put(:monster, boss)
            |> add_separator(:boss_encounter)
            |> add_to_history("=== ENTERING FLOOR #{floor} ===", :boss_encounter)
            |> add_to_history("💀 #{boss.name} blocks your path! 💀", :boss_encounter)
            |> add_separator(:boss_encounter)

          {:error, :no_boss_found} ->
            # Fallback to regular monster if boss not found
            spawn_regular_monster(state)
        end

      false ->
        spawn_regular_monster(state)
    end
  end

  defp spawn_regular_monster(state) do
    new_monster = MonsterRepo.get_monster_for_level(state.hero.level, state.difficulty)

    state
    |> Map.put(:monster, new_monster)
    |> add_to_history("A wild #{new_monster.display_name} appears!", :system)
  end

  defp should_spawn_boss?(level) do
    # Boss appears every 10 levels (10, 20, 30, etc.)
    rem(level, 10) == 0 and level > 0
  end

  defp check_level_up(state) do
    if Hero.should_level_up?(state.hero) do
      updated_hero = Hero.level_up(state.hero)

      state
      |> Map.put(:hero, updated_hero)
      |> add_separator(:level_up)
      |> add_to_history("LEVEL UP!", :level_up)
      |> add_to_history("You are now level #{updated_hero.level}!", :level_up)
      |> add_to_history("Max HP: #{updated_hero.hp_max}", :level_up)
      |> add_to_history(
        "Damage: #{updated_hero.damage_min}-#{updated_hero.damage_max}",
        :level_up
      )
      |> add_to_history("Heal: #{updated_hero.heal_min}-#{updated_hero.heal_max}", :level_up)
      |> add_separator(:level_up)
    else
      state
    end
  end

  defp add_separator(state, type) do
    separator = HistoryEntry.separator(type)
    %{state | history: [separator | state.history]}
  end

  defp handle_potion_drop(state) do
    case PotionConfigRepo.roll_for_drop() do
      {:drop, quality} ->
        potion = PotionConfigRepo.generate_random_potion(quality)

        # Try to add to inventory
        case Hero.add_potion_to_inventory(state.hero, potion) do
          {:ok, updated_hero} ->
            # Success! Added to inventory
            state
            |> Map.put(:hero, updated_hero)
            |> add_to_history("A #{potion.display_name} dropped!", :item)

          {:full, _hero} ->
            # Inventory full, show modal
            state
            |> Map.put(:pending_potion_drop, potion)
            |> Map.put(:show_potion_pickup_modal, true)
            |> add_to_history(
              "A #{potion.display_name} dropped, but your inventory is full!",
              :item
            )
        end

      :no_drop ->
        state
    end
  end

  @doc """
  Handle picking up a potion drop, optionally replacing an existing potion.
  """
  @spec handle_pickup_potion(t(), non_neg_integer() | nil) :: t()
  def handle_pickup_potion(state, nil) do
    # Try to add without replacement (shouldn't happen but handle it)
    case state.pending_potion_drop do
      nil ->
        close_pickup_modal(state)

      potion ->
        case Hero.add_potion_to_inventory(state.hero, potion) do
          {:ok, updated_hero} ->
            state
            |> Map.put(:hero, updated_hero)
            |> Map.put(:pending_potion_drop, nil)
            |> Map.put(:show_potion_pickup_modal, false)
            |> add_to_history("Picked up #{potion.display_name}!", :item)

          {:full, _} ->
            # Still full, shouldn't happen
            close_pickup_modal(state)
        end
    end
  end

  def handle_pickup_potion(state, replace_slot_index) do
    case state.pending_potion_drop do
      nil ->
        close_pickup_modal(state)

      new_potion ->
        case Hero.replace_potion_in_inventory(state.hero, replace_slot_index, new_potion) do
          {:ok, updated_hero, old_potion} ->
            message =
              if old_potion do
                "Swapped #{old_potion.display_name} for #{new_potion.display_name}!"
              else
                "Picked up #{new_potion.display_name}!"
              end

            state
            |> Map.put(:hero, updated_hero)
            |> Map.put(:pending_potion_drop, nil)
            |> Map.put(:show_potion_pickup_modal, false)
            |> add_to_history(message, :item)

          {:error, _reason} ->
            # Handle invalid slot gracefully by closing modal
            close_pickup_modal(state)
        end
    end
  end

  @doc """
  Decline picking up the potion drop.
  """
  @spec handle_decline_potion(t()) :: t()
  def handle_decline_potion(state) do
    case state.pending_potion_drop do
      nil ->
        close_pickup_modal(state)

      potion ->
        state
        |> Map.put(:pending_potion_drop, nil)
        |> Map.put(:show_potion_pickup_modal, false)
        |> add_to_history("Left #{potion.display_name} behind.", :item)
    end
  end

  @doc """
  Handle claiming boss reward (Major potion of chosen type).
  Spawns next monster after reward is claimed.
  """
  @spec handle_claim_boss_reward(t(), String.t()) :: t()
  def handle_claim_boss_reward(state, potion_type) when potion_type in ["healing", "damage"] do
    # Create a Major potion of the chosen type
    potion = case potion_type do
      "healing" -> Potion.new(:major, :healing, nil)
      "damage" ->
        # Generate a random damage flavor from available flavors
        flavors = [:fire, :acid, :lightning, :poison, :frost, :arcane, :shadow, :radiant]
        flavor = Enum.random(flavors)
        Potion.new(:major, :damage, flavor)
    end

    # Try to add to inventory
    case Hero.add_potion_to_inventory(state.hero, potion) do
      {:ok, updated_hero} ->
        # Success! Added to inventory, clear reward flag, spawn next monster
        state
        |> Map.put(:hero, updated_hero)
        |> Map.put(:pending_boss_reward, false)
        |> add_to_history("Received #{potion.display_name} as boss reward!", :item)
        |> spawn_next_monster()

      {:full, hero} ->
        # Inventory still full (shouldn't happen if UI is correct, but handle gracefully)
        # For now, just clear the reward and spawn next monster without giving potion
        state
        |> Map.put(:hero, hero)
        |> Map.put(:pending_boss_reward, false)
        |> add_to_history("Inventory full! Boss reward lost.", :item)
        |> spawn_next_monster()
    end
  end

  @doc """
  Handle using a potion from inventory.
  """
  @spec handle_use_potion(t(), non_neg_integer()) :: t()
  def handle_use_potion(state, slot_index) do
    case Hero.use_healing_potion(state.hero, slot_index) do
      {:ok, updated_hero, heal_amount} ->
        state
        |> Map.put(:hero, updated_hero)
        |> Map.put(:show_potion_use_modal, false)
        |> Map.put(:selected_potion_slot, nil)
        |> Map.put(:selected_potion, nil)
        |> add_to_history("Used potion and healed #{heal_amount} HP!", :healing)

      {:error, :not_healing_potion} ->
        # It's a damage potion
        case Hero.use_damage_potion(state.hero, slot_index) do
          {:ok, updated_hero, potion} ->
            # Calculate damage and apply to monster
            damage = Potion.calculate_damage(potion, state.monster.hp)
            updated_monster = Monster.take_damage(state.monster, damage)

            state =
              state
              |> Map.put(:hero, updated_hero)
              |> Map.put(:monster, updated_monster)
              |> Map.put(:show_potion_use_modal, false)
              |> Map.put(:selected_potion_slot, nil)
              |> Map.put(:selected_potion, nil)
              |> add_to_history(
                "Threw #{potion.display_name} dealing #{damage} damage!",
                :combat
              )

            # Check if monster defeated
            if Monster.defeated?(updated_monster) do
              handle_monster_death(state)
            else
              # Monster counter-attacks
              handle_monster_attack(state)
            end

          {:error, _} ->
            close_use_modal(state)
        end

      {:error, _} ->
        close_use_modal(state)
    end
  end

  @doc """
  Show the potion use confirmation modal.
  """
  @spec show_use_potion_modal(t(), non_neg_integer()) :: t()
  def show_use_potion_modal(state, slot_index) do
    case Inventory.get_potion(state.hero.inventory, slot_index) do
      {:ok, potion} ->
        state
        |> Map.put(:show_potion_use_modal, true)
        |> Map.put(:selected_potion_slot, slot_index)
        |> Map.put(:selected_potion, potion)

      {:error, _} ->
        state
    end
  end

  @doc """
  Close the potion use modal without using the potion.
  """
  @spec close_use_modal(t()) :: t()
  def close_use_modal(state) do
    state
    |> Map.put(:show_potion_use_modal, false)
    |> Map.put(:selected_potion_slot, nil)
    |> Map.put(:selected_potion, nil)
  end

  defp close_pickup_modal(state) do
    state
    |> Map.put(:show_potion_pickup_modal, false)
    |> Map.put(:pending_potion_drop, nil)
  end
end
