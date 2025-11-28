defmodule SuperDungeonSlaughterExWeb.GameComponents do
  @moduledoc """
  Game-specific UI components for Super Dungeon Slaughter EX.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias SuperDungeonSlaughterEx.Game.{Hero, Monster, Potion}
  alias SuperDungeonSlaughterEx.Score

  @doc """
  Game history display component showing scrollable combat log with icons and colors.
  """
  attr :history, :list, required: true

  def game_history(assigns) do
    ~H"""
    <div
      id="game-history"
      phx-hook="ScrollToBottom"
      class="border-2 border-gray-700 rounded bg-black h-[600px] overflow-y-auto p-4"
    >
      <div class="space-y-1 font-mono text-sm">
        <%= for entry <- Enum.reverse(@history) do %>
          <div class={[
            "flex items-start gap-2 py-0.5",
            SuperDungeonSlaughterEx.Game.HistoryEntry.get_color_class(entry.type),
            entry.type == :level_up && "font-bold"
          ]}>
            <span class="text-base flex-shrink-0">{entry.icon}</span>
            <span class="flex-1">{entry.message}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Hero stats panel component with integrated inventory display.
  """
  attr :hero, :map, required: true

  def hero_stats(assigns) do
    ~H"""
    <div class="border-2 border-orange-500 p-4 rounded bg-gray-800">
      <h2 class="text-xl font-bold text-orange-400 mb-3">Player Stats</h2>
      <div class="space-y-2">
        <div class="flex justify-between">
          <span>Name:</span>
          <span class="text-yellow-400 font-bold">{@hero.name}</span>
        </div>
        <div class="flex justify-between">
          <span>Floor:</span>
          <span class="text-cyan-400">{@hero.current_floor}</span>
        </div>
        <div class="flex justify-between">
          <span>Kill Count:</span>
          <span class="text-yellow-400">{@hero.total_kills}</span>
        </div>
        <div class="flex justify-between">
          <span>Level:</span>
          <span class="text-yellow-400">{@hero.level}</span>
        </div>
        <div>
          <div class="flex justify-between mb-1">
            <span>HP:</span>
            <span class={hp_color(@hero)}>{@hero.hp}/{@hero.hp_max}</span>
          </div>
          <.hp_bar percentage={Hero.hp_percentage(@hero)} />
        </div>
        <div class="flex justify-between text-sm">
          <span>Damage:</span>
          <span class="text-gray-400">{@hero.damage_min}-{@hero.damage_max}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span>Heal:</span>
          <span class="text-gray-400">{@hero.heal_min}-{@hero.heal_max}</span>
        </div>
      </div>
      <.inventory_display inventory={@hero.inventory} />
    </div>
    """
  end

  @doc """
  Monster stats panel component.
  """
  attr :monster, :map, required: true

  def monster_stats(assigns) do
    ~H"""
    <div class={[
      "border-2 p-4 rounded bg-gray-800",
      @monster.is_boss && "border-red-500 animate-pulse",
      !@monster.is_boss && "border-orange-500"
    ]}>
      <h2 class={[
        "text-xl font-bold mb-3",
        @monster.is_boss && "text-red-400 text-2xl",
        !@monster.is_boss && "text-orange-400"
      ]}>
        <%= if @monster.is_boss do %>
          ⚔️ BOSS FIGHT ⚔️
        <% else %>
          Monster Stats
        <% end %>
      </h2>
      <div class="space-y-2">
        <div class={[
          "text-lg font-semibold",
          @monster.is_boss && "text-red-300 text-xl",
          !@monster.is_boss && "text-purple-400"
        ]}>
          {@monster.display_name}
        </div>
        <div>
          <div class="flex justify-between mb-1">
            <span>HP:</span>
            <span class={hp_color(@monster)}>{@monster.hp}/{@monster.hp_max}</span>
          </div>
          <.hp_bar percentage={Monster.hp_percentage(@monster)} />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  HP bar component with color coding.
  """
  attr :percentage, :float, required: true

  def hp_bar(assigns) do
    ~H"""
    <div class="w-full bg-gray-700 rounded h-4">
      <div
        class={"h-full rounded transition-all duration-300 #{hp_bar_color(@percentage)}"}
        style={"width: #{@percentage * 100}%"}
      />
    </div>
    """
  end

  @doc """
  Inventory display component showing 5 potion slots.
  Empty slots are grayed out, filled slots are clickable with hover effects.
  """
  attr :inventory, :map, required: true

  def inventory_display(assigns) do
    ~H"""
    <div class="mt-4 pt-4 border-t-2 border-gray-700">
      <h3 class="text-lg font-bold text-orange-400 mb-2">Inventory</h3>
      <div class="grid grid-cols-5 gap-2">
        <%= for {slot, index} <- Enum.with_index(@inventory.slots) do %>
          <%= if slot do %>
            <button
              phx-click="show_use_potion_modal"
              phx-value-slot={index}
              class={[
                "aspect-square rounded border-2 flex items-center justify-center transition-all",
                "hover:scale-105 hover:shadow-lg cursor-pointer",
                Potion.get_bg_color_class(slot),
                Potion.get_border_color_class(slot)
              ]}
              title={slot.display_name}
            >
              <span class={[Potion.get_color_class(slot), Potion.get_icon_size_class(slot)]}>
                {Potion.get_icon(slot)}
              </span>
            </button>
          <% else %>
            <div class="aspect-square rounded border-2 border-gray-600 bg-gray-700 flex items-center justify-center opacity-50">
              <span class="text-gray-500 text-sm">Empty</span>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Potion use confirmation modal.
  Shows potion details and asks for confirmation before use.
  """
  attr :potion, :map, required: true
  attr :slot_index, :integer, required: true
  attr :hero, :map, required: true

  def potion_use_modal(assigns) do
    effect_description =
      case assigns.potion.category do
        :healing ->
          heal_amount = Potion.calculate_healing(assigns.potion, assigns.hero.hp_max)
          "Restore #{heal_amount} HP (#{get_percentage_text(assigns.potion.quality)} of max HP)"

        :damage ->
          "Throw at monster (deals #{get_percentage_text(assigns.potion.quality)} of monster's current HP)"
      end

    assigns = assign(assigns, :effect_description, effect_description)

    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-purple-500 rounded-lg p-6 max-w-md w-full mx-4">
        <h2 class="text-2xl font-bold text-purple-400 text-center mb-4">Use Potion?</h2>

        <div class={[
          "rounded-lg p-6 mb-4 flex flex-col items-center border-2",
          Potion.get_bg_color_class(@potion),
          Potion.get_border_color_class(@potion)
        ]}>
          <span class={[Potion.get_color_class(@potion), "text-5xl mb-2"]}>
            {Potion.get_icon(@potion)}
          </span>
          <div class={["text-xl font-bold mb-2", Potion.get_color_class(@potion)]}>
            {@potion.display_name}
          </div>
          <div class="text-gray-300 text-center text-sm">
            {@effect_description}
          </div>
        </div>

        <div class="flex gap-3">
          <button
            phx-click="cancel_use_potion"
            class="flex-1 py-3 bg-gray-600 hover:bg-gray-700 text-white font-bold rounded transition-colors"
          >
            Cancel
          </button>
          <button
            phx-click="use_potion"
            phx-value-slot={@slot_index}
            class="flex-1 py-3 bg-green-600 hover:bg-green-700 text-white font-bold rounded transition-colors"
          >
            Use It!
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Potion pickup/swap modal.
  Shows when inventory is full and offers to swap potions.
  """
  attr :dropped_potion, :map, required: true
  attr :hero, :map, required: true

  def potion_pickup_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-6 max-w-lg w-full mx-4">
        <h2 class="text-2xl font-bold text-yellow-400 text-center mb-4">
          Inventory Full!
        </h2>

        <div class="mb-4">
          <p class="text-center text-gray-300 mb-4">
            A potion dropped, but your inventory is full. Swap with an existing potion?
          </p>

          <div class={[
            "rounded-lg p-4 flex flex-col items-center border-2 mb-4",
            Potion.get_bg_color_class(@dropped_potion),
            Potion.get_border_color_class(@dropped_potion)
          ]}>
            <span class={[Potion.get_color_class(@dropped_potion), "text-4xl mb-1"]}>
              {Potion.get_icon(@dropped_potion)}
            </span>
            <div class={["font-bold", Potion.get_color_class(@dropped_potion)]}>
              {@dropped_potion.display_name}
            </div>
          </div>

          <h3 class="text-lg font-bold text-orange-400 mb-2">Your Inventory:</h3>
          <div class="grid grid-cols-5 gap-2">
            <%= for {slot, index} <- Enum.with_index(@hero.inventory.slots) do %>
              <%= if slot do %>
                <button
                  phx-click="pickup_potion"
                  phx-value-slot={index}
                  class={[
                    "aspect-square rounded border-2 flex items-center justify-center transition-all",
                    "hover:scale-105 hover:shadow-lg cursor-pointer hover:border-yellow-400",
                    Potion.get_bg_color_class(slot),
                    Potion.get_border_color_class(slot)
                  ]}
                  title={"Replace with #{slot.display_name}"}
                >
                  <span class={[Potion.get_color_class(slot), Potion.get_icon_size_class(slot)]}>
                    {Potion.get_icon(slot)}
                  </span>
                </button>
              <% end %>
            <% end %>
          </div>
        </div>

        <button
          phx-click="decline_potion"
          class="w-full py-3 bg-red-600 hover:bg-red-700 text-white font-bold rounded transition-colors"
        >
          Leave It Behind
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Boss reward modal - shown after defeating a boss.
  Allows player to choose between Major Healing or Major Damage potion.
  """
  attr :current_floor, :integer, required: true

  def boss_reward_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-8 max-w-md w-full mx-4">
        <h2 class="text-3xl font-bold text-yellow-400 text-center mb-4">
          🏆 BOSS DEFEATED! 🏆
        </h2>

        <p class="text-green-400 text-center mb-6">
          You have conquered Floor {@current_floor}!<br /> Your wounds heal as you rest.
        </p>

        <div class="bg-black p-4 rounded mb-6">
          <h3 class="text-xl text-purple-400 mb-3 text-center">Choose Your Reward:</h3>
          <div class="flex gap-4 justify-center">
            <button
              phx-click="claim_boss_reward"
              phx-value-type="healing"
              class="flex-1 px-6 py-4 bg-green-600 hover:bg-green-700 rounded transition-colors flex flex-col items-center gap-2 border-2 border-green-500 hover:border-green-300"
            >
              <span class="text-4xl">🏺</span>
              <span class="font-bold text-white">Major Healing<br />Potion</span>
            </button>
            <button
              phx-click="claim_boss_reward"
              phx-value-type="damage"
              class="flex-1 px-6 py-4 bg-red-600 hover:bg-red-700 rounded transition-colors flex flex-col items-center gap-2 border-2 border-red-500 hover:border-red-300"
            >
              <span class="text-4xl">🏺</span>
              <span class="font-bold text-white">Major Damage<br />Potion</span>
            </button>
          </div>
        </div>

        <p class="text-gray-400 text-sm text-center italic">
          The path ahead grows darker...
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Game over statistics modal overlay.
  """
  attr :hero, :map, required: true
  attr :show_high_scores, :boolean, default: false

  def game_over_stats(assigns) do
    assigns = assign(assigns, :stats, Hero.get_statistics(assigns.hero))

    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-red-500 rounded-lg p-8 max-w-2xl w-full mx-4">
        <h2 class="text-4xl font-bold text-red-500 text-center mb-6">Game Over!</h2>

        <div class="bg-black p-6 rounded mb-6 space-y-3 font-mono">
          <h3 class="text-2xl text-yellow-400 mb-4">Final Statistics</h3>

          <div class="flex justify-between text-green-400">
            <span>Level Achieved:</span>
            <span class="text-yellow-300 font-bold">{@stats.level}</span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Monsters Killed:</span>
            <span class="text-yellow-300 font-bold">{@stats.kills}</span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Total Damage Dealt:</span>
            <span class="text-yellow-300 font-bold">{@stats.damage_dealt}</span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Total Health Healed:</span>
            <span class="text-yellow-300 font-bold">{@stats.health_healed}</span>
          </div>

          <%= if @stats.monster_breakdown != [] do %>
            <div class="mt-6">
              <h4 class="text-xl text-purple-400 mb-3">Monster Kill Breakdown</h4>
              <div class="space-y-1">
                <%= for {monster_name, count} <- @stats.monster_breakdown do %>
                  <div class="flex justify-between text-green-300">
                    <span>{monster_name}:</span>
                    <span class="text-yellow-300">{count}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex gap-4">
          <button
            phx-click="toggle_high_scores"
            class="flex-1 py-4 bg-purple-600 hover:bg-purple-700 text-white text-xl font-bold rounded transition-colors"
          >
            {if @show_high_scores, do: "Back to Stats", else: "View High Scores"}
          </button>
          <button
            phx-click="new_game"
            class="flex-1 py-4 bg-green-600 hover:bg-green-700 text-white text-xl font-bold rounded transition-colors"
          >
            New Game?
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Start page high scores display component showing all difficulties.
  Shows top 10 scores for each difficulty without player highlighting.
  """
  attr :all_scores, :list, required: true

  def start_page_high_scores_all_difficulties(assigns) do
    easy_scores = Enum.filter(assigns.all_scores, &(&1.difficulty == :easy)) |> Enum.take(10)
    normal_scores = Enum.filter(assigns.all_scores, &(&1.difficulty == :normal)) |> Enum.take(10)
    hard_scores = Enum.filter(assigns.all_scores, &(&1.difficulty == :hard)) |> Enum.take(10)

    assigns =
      assigns
      |> assign(:easy_scores, easy_scores)
      |> assign(:normal_scores, normal_scores)
      |> assign(:hard_scores, hard_scores)

    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 overflow-y-auto">
      <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-8 max-w-4xl w-full mx-4 my-8">
        <h2 class="text-4xl font-bold text-yellow-400 text-center mb-6">High Scores</h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-black p-4 rounded border-2 border-blue-500">
            <h3 class="text-2xl font-bold text-blue-400 text-center mb-3">Easy</h3>
            <div class="space-y-1 font-mono text-sm max-h-[300px] overflow-y-auto">
              <%= if @easy_scores == [] do %>
                <div class="text-center text-gray-400 py-4 text-xs">No scores yet</div>
              <% else %>
                <%= for {score, index} <- Enum.with_index(@easy_scores, 1) do %>
                  <div class="flex justify-between p-1 text-xs">
                    <div class="flex gap-2">
                      <span class={["w-4 text-right", rank_color(index)]}>{index}.</span>
                      <span class="truncate max-w-[80px]">{score.name}</span>
                    </div>
                    <div class="flex gap-2">
                      <span class="text-yellow-400">L{score.level}</span>
                      <span class="text-purple-400">{score.kills}</span>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="bg-black p-4 rounded border-2 border-green-500">
            <h3 class="text-2xl font-bold text-green-400 text-center mb-3">Normal</h3>
            <div class="space-y-1 font-mono text-sm max-h-[300px] overflow-y-auto">
              <%= if @normal_scores == [] do %>
                <div class="text-center text-gray-400 py-4 text-xs">No scores yet</div>
              <% else %>
                <%= for {score, index} <- Enum.with_index(@normal_scores, 1) do %>
                  <div class="flex justify-between p-1 text-xs">
                    <div class="flex gap-2">
                      <span class={["w-4 text-right", rank_color(index)]}>{index}.</span>
                      <span class="truncate max-w-[80px]">{score.name}</span>
                    </div>
                    <div class="flex gap-2">
                      <span class="text-yellow-400">L{score.level}</span>
                      <span class="text-purple-400">{score.kills}</span>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="bg-black p-4 rounded border-2 border-red-500">
            <h3 class="text-2xl font-bold text-red-400 text-center mb-3">Hard</h3>
            <div class="space-y-1 font-mono text-sm max-h-[300px] overflow-y-auto">
              <%= if @hard_scores == [] do %>
                <div class="text-center text-gray-400 py-4 text-xs">No scores yet</div>
              <% else %>
                <%= for {score, index} <- Enum.with_index(@hard_scores, 1) do %>
                  <div class="flex justify-between p-1 text-xs">
                    <div class="flex gap-2">
                      <span class={["w-4 text-right", rank_color(index)]}>{index}.</span>
                      <span class="truncate max-w-[80px]">{score.name}</span>
                    </div>
                    <div class="flex gap-2">
                      <span class="text-yellow-400">L{score.level}</span>
                      <span class="text-purple-400">{score.kills}</span>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>

        <button
          phx-click="toggle_high_scores"
          class="w-full py-4 bg-purple-600 hover:bg-purple-700 text-white text-xl font-bold rounded transition-colors"
        >
          Back
        </button>
      </div>
    </div>
    """
  end

  @doc """
  High scores display component.
  Shows top 10 scores for the specified difficulty, highlights player's score if in top 10,
  or shows player's placement if outside top 10.
  """
  attr :all_scores, :list, required: true
  attr :player_name, :string, required: true
  attr :player_level, :integer, required: true
  attr :player_kills, :integer, required: true

  attr :difficulty, :atom,
    required: true,
    doc: "Game difficulty (SuperDungeonSlaughterEx.Types.difficulty())"

  def high_scores_display(assigns) do
    top_10 = Enum.take(assigns.all_scores, 10)

    player_score = %Score{
      name: assigns.player_name,
      level: assigns.player_level,
      kills: assigns.player_kills
    }

    player_rank = find_player_rank(assigns.all_scores, player_score)
    player_in_top_10 = player_rank <= 10

    assigns =
      assigns
      |> assign(:top_10, top_10)
      |> assign(:player_rank, player_rank)
      |> assign(:player_in_top_10, player_in_top_10)
      |> assign(:player_score, player_score)

    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-8 max-w-2xl w-full mx-4">
        <h2 class="text-4xl font-bold text-yellow-400 text-center mb-2">High Scores</h2>
        <div class={[
          "text-2xl font-bold text-center mb-4",
          difficulty_color(@difficulty)
        ]}>
          {difficulty_label(@difficulty)}
        </div>

        <div class="bg-black p-6 rounded mb-6 space-y-2 font-mono max-h-[500px] overflow-y-auto">
          <%= for {score, index} <- Enum.with_index(@top_10, 1) do %>
            <div class={[
              "flex justify-between p-2 rounded",
              is_player_score?(score, @player_score, @player_in_top_10) &&
                "bg-green-900 border-2 border-green-400"
            ]}>
              <div class="flex gap-4 flex-1">
                <span class={[
                  "w-8 text-right font-bold",
                  rank_color(index)
                ]}>
                  {index}.
                </span>
                <span class={[
                  "flex-1",
                  is_player_score?(score, @player_score, @player_in_top_10) &&
                    "text-green-300 font-bold"
                ]}>
                  {score.name}
                </span>
              </div>
              <div class="flex gap-6">
                <span class={[
                  "text-yellow-400",
                  is_player_score?(score, @player_score, @player_in_top_10) && "font-bold"
                ]}>
                  Lvl {score.level}
                </span>
                <span class={[
                  "text-purple-400 w-16 text-right",
                  is_player_score?(score, @player_score, @player_in_top_10) && "font-bold"
                ]}>
                  {score.kills} kills
                </span>
              </div>
            </div>
          <% end %>

          <%= if !@player_in_top_10 do %>
            <div class="mt-6 pt-4 border-t-2 border-gray-600">
              <div class="flex justify-between p-2 rounded bg-blue-900 border-2 border-blue-400">
                <div class="flex gap-4 flex-1">
                  <span class="w-8 text-right font-bold text-blue-300">{@player_rank}.</span>
                  <span class="flex-1 text-blue-200 font-bold">
                    {@player_score.name} (Your Score)
                  </span>
                </div>
                <div class="flex gap-6">
                  <span class="text-yellow-400 font-bold">Lvl {@player_score.level}</span>
                  <span class="text-purple-400 font-bold w-16 text-right">
                    {@player_score.kills} kills
                  </span>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex gap-4">
          <button
            phx-click="toggle_high_scores"
            class="flex-1 py-4 bg-purple-600 hover:bg-purple-700 text-white text-xl font-bold rounded transition-colors"
          >
            Back to Stats
          </button>
          <button
            phx-click="new_game"
            class="flex-1 py-4 bg-green-600 hover:bg-green-700 text-white text-xl font-bold rounded transition-colors"
          >
            New Game?
          </button>
        </div>
      </div>
    </div>
    """
  end

  # Helper Functions

  defp hp_bar_color(percentage) when percentage > 0.66, do: "bg-green-500"
  defp hp_bar_color(percentage) when percentage > 0.33, do: "bg-yellow-500"
  defp hp_bar_color(_), do: "bg-red-500"

  defp hp_color(%{hp: hp, hp_max: max}) when max > 0 do
    percentage = hp / max
    hp_color_by_percentage(percentage)
  end

  defp hp_color(_), do: "text-red-400"

  defp hp_color_by_percentage(percentage) when percentage > 0.66, do: "text-green-400"
  defp hp_color_by_percentage(percentage) when percentage > 0.33, do: "text-yellow-400"
  defp hp_color_by_percentage(_), do: "text-red-400"

  defp rank_color(1), do: "text-yellow-300"
  defp rank_color(2), do: "text-gray-300"
  defp rank_color(3), do: "text-orange-400"
  defp rank_color(_), do: "text-gray-500"

  defp is_player_score?(score, player_score, player_in_top_10) do
    player_in_top_10 and score.name == player_score.name and
      score.level == player_score.level and score.kills == player_score.kills
  end

  defp find_player_rank(all_scores, player_score) do
    all_scores
    |> Enum.with_index(1)
    |> Enum.find_value(fn {score, index} ->
      if score.name == player_score.name and score.level == player_score.level and
           score.kills == player_score.kills do
        index
      end
    end) || length(all_scores) + 1
  end

  defp get_percentage_text(:minor), do: "25%"
  defp get_percentage_text(:normal), do: "50%"
  defp get_percentage_text(:major), do: "100%"

  # Difficulty label helpers (SuperDungeonSlaughterEx.Types.difficulty())
  defp difficulty_label(:easy), do: "Easy Mode"
  defp difficulty_label(:hard), do: "Hard Mode"
  defp difficulty_label(_), do: "Normal Mode"

  # Difficulty color helpers (SuperDungeonSlaughterEx.Types.difficulty())
  defp difficulty_color(:easy), do: "text-blue-400"
  defp difficulty_color(:hard), do: "text-red-400"
  defp difficulty_color(_), do: "text-green-400"

  @doc """
  Settings modal component with theme selector and other future settings.
  """
  def settings_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4">
      <div class="bg-gray-800 border-4 border-orange-500 rounded-lg p-8 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <h2 class="text-3xl font-bold text-orange-400 mb-6 text-center">Settings</h2>

        <div class="space-y-6">
          <!-- Theme Selector -->
          <div>
            <h3 class="text-xl font-bold text-green-400 mb-4">Visual Theme</h3>
            <p class="text-gray-400 text-sm mb-4">
              Select a visual theme to customize the game's appearance
            </p>

            <!-- Light Themes -->
            <div class="mb-4">
              <h4 class="text-md font-semibold text-gray-300 mb-2">Light Themes</h4>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="light"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=light]_&]:bg-green-900/30 [[data-theme=light]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Light</div>
                  <div class="text-xs text-gray-400">Clean & modern</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="ink"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=ink]_&]:bg-green-900/30 [[data-theme=ink]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Ink & Brush</div>
                  <div class="text-xs text-gray-400">Hand-drawn style</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="parchment"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=parchment]_&]:bg-green-900/30 [[data-theme=parchment]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Parchment</div>
                  <div class="text-xs text-gray-400">Aged manuscript</div>
                </button>
              </div>
            </div>

            <!-- Dark Themes -->
            <div>
              <h4 class="text-md font-semibold text-gray-300 mb-2">Dark Themes</h4>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="dark"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=dark]_&]:bg-green-900/30 [[data-theme=dark]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Dark</div>
                  <div class="text-xs text-gray-400">Modern dark theme</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="arcade"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=arcade]_&]:bg-green-900/30 [[data-theme=arcade]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Arcade</div>
                  <div class="text-xs text-gray-400">Retro arcade cabinet</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="fantasy"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=fantasy]_&]:bg-green-900/30 [[data-theme=fantasy]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">High Fantasy</div>
                  <div class="text-xs text-gray-400">Mystical & magical</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="terminal"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=terminal]_&]:bg-green-900/30 [[data-theme=terminal]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Terminal</div>
                  <div class="text-xs text-gray-400">Classic CRT monitor</div>
                </button>

                <button
                  phx-click={JS.dispatch("phx:set-theme")}
                  data-phx-theme="cyberpunk"
                  class="p-3 bg-gray-700 hover:bg-gray-600 border-2 border-gray-600 hover:border-green-500 rounded text-left transition-all [[data-theme=cyberpunk]_&]:bg-green-900/30 [[data-theme=cyberpunk]_&]:border-green-500"
                >
                  <div class="font-bold text-green-400">Cyberpunk</div>
                  <div class="text-xs text-gray-400">Neon & electric</div>
                </button>
              </div>
            </div>
          </div>

          <!-- Future settings can be added here -->
          <div class="border-t-2 border-gray-600 pt-4">
            <p class="text-gray-500 text-sm italic">More settings coming soon...</p>
          </div>
        </div>

        <div class="mt-6">
          <button
            phx-click="toggle_settings"
            class="w-full py-3 bg-orange-600 hover:bg-orange-700 text-white text-xl font-bold rounded transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
    """
  end
end
