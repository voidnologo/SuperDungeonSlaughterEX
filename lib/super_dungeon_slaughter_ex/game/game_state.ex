defmodule SuperDungeonSlaughterEx.Game.GameState do
  @moduledoc """
  Main game state container managing hero, monster, combat history, and game over status.
  """

  alias SuperDungeonSlaughterEx.Game.{Hero, Monster}
  alias SuperDungeonSlaughterEx.Repos.MonsterRepo

  @max_history 200

  @type t :: %__MODULE__{
          hero: Hero.t(),
          monster: Monster.t(),
          history: [String.t()],
          game_over: boolean()
        }

  defstruct [:hero, :monster, history: [], game_over: false]

  @doc """
  Create a new game state with a hero and first monster.
  """
  @spec new(String.t()) :: t()
  def new(hero_name) do
    hero = Hero.new(hero_name)
    monster = MonsterRepo.get_monster_for_level(hero.level)

    %__MODULE__{
      hero: hero,
      monster: monster,
      history: ["Welcome, #{hero_name}! A wild #{monster.name} appears!"]
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
      |> add_to_history("#{updated_hero.name} deals #{damage} damage to the #{updated_monster.name}!")

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
      |> add_to_history("#{updated_hero.name} heals #{heal} HP!")

    # Monster attacks
    handle_monster_attack(state)
  end

  @doc """
  Add a message to the history (newest first), limiting total history size.
  """
  @spec add_to_history(t(), String.t()) :: t()
  def add_to_history(state, message) do
    history = [message | state.history] |> Enum.take(@max_history)
    %{state | history: history}
  end

  # Private Functions

  defp handle_monster_attack(state) do
    damage = Monster.attack(state.monster)
    updated_hero = Hero.take_damage(state.hero, damage)

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history("#{state.monster.name} deals #{damage} damage to #{updated_hero.name}!")

    # Check if hero defeated
    if Hero.defeated?(updated_hero) do
      state
      |> Map.put(:game_over, true)
      |> add_to_history("You died! You managed to kill #{updated_hero.total_kills} monsters.")
    else
      state
    end
  end

  defp handle_monster_death(state) do
    # Record the kill
    updated_hero = Hero.record_kill(state.hero, state.monster.name)

    state =
      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history("Congratulations! You killed the #{state.monster.name}!")
      |> add_to_history("You have killed #{updated_hero.total_kills} monsters.")

    # Check for level up
    state = check_level_up(state)

    # Spawn new monster
    new_monster = MonsterRepo.get_monster_for_level(state.hero.level)

    state
    |> Map.put(:monster, new_monster)
    |> add_to_history("Prepare for your next fight!")
    |> add_to_history("A wild #{new_monster.name} appears!")
  end

  defp check_level_up(state) do
    if Hero.should_level_up?(state.hero) do
      updated_hero = Hero.level_up(state.hero)

      state
      |> Map.put(:hero, updated_hero)
      |> add_to_history("You gained a level!")
      |> add_to_history("You are now level #{updated_hero.level}!")
      |> add_to_history("Max HP: #{updated_hero.hp_max}")
      |> add_to_history(
        "Damage: #{updated_hero.damage_min}-#{updated_hero.damage_max}"
      )
      |> add_to_history("Heal: #{updated_hero.heal_min}-#{updated_hero.heal_max}")
    else
      state
    end
  end
end
