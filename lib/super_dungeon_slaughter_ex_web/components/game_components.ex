defmodule SuperDungeonSlaughterExWeb.GameComponents do
  @moduledoc """
  Game-specific UI components for Super Dungeon Slaughter EX.
  """

  use Phoenix.Component
  alias SuperDungeonSlaughterEx.Game.{Hero, Monster}
  alias SuperDungeonSlaughterEx.Score

  @doc """
  Game history display component showing scrollable combat log.
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
        <%= for message <- Enum.reverse(@history) do %>
          <div class="text-green-300"><%= message %></div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Hero stats panel component.
  """
  attr :hero, :map, required: true

  def hero_stats(assigns) do
    ~H"""
    <div class="border-2 border-orange-500 p-4 rounded bg-gray-800">
      <h2 class="text-xl font-bold text-orange-400 mb-3">Player Stats</h2>
      <div class="space-y-2">
        <div class="flex justify-between">
          <span>Name:</span>
          <span class="text-yellow-400 font-bold"><%= @hero.name %></span>
        </div>
        <div class="flex justify-between">
          <span>Kill Count:</span>
          <span class="text-yellow-400"><%= @hero.total_kills %></span>
        </div>
        <div class="flex justify-between">
          <span>Level:</span>
          <span class="text-yellow-400"><%= @hero.level %></span>
        </div>
        <div>
          <div class="flex justify-between mb-1">
            <span>HP:</span>
            <span class={hp_color(@hero)}><%= @hero.hp %>/<%= @hero.hp_max %></span>
          </div>
          <.hp_bar percentage={Hero.hp_percentage(@hero)} />
        </div>
        <div class="flex justify-between text-sm">
          <span>Damage:</span>
          <span class="text-gray-400"><%= @hero.damage_min %>-<%= @hero.damage_max %></span>
        </div>
        <div class="flex justify-between text-sm">
          <span>Heal:</span>
          <span class="text-gray-400"><%= @hero.heal_min %>-<%= @hero.heal_max %></span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Monster stats panel component.
  """
  attr :monster, :map, required: true

  def monster_stats(assigns) do
    ~H"""
    <div class="border-2 border-orange-500 p-4 rounded bg-gray-800">
      <h2 class="text-xl font-bold text-orange-400 mb-3">Monster Stats</h2>
      <div class="space-y-2">
        <div class="text-lg font-semibold text-purple-400">
          <%= @monster.name %>
        </div>
        <div>
          <div class="flex justify-between mb-1">
            <span>HP:</span>
            <span class={hp_color(@monster)}><%= @monster.hp %>/<%= @monster.hp_max %></span>
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
            <span class="text-yellow-300 font-bold"><%= @stats.level %></span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Monsters Killed:</span>
            <span class="text-yellow-300 font-bold"><%= @stats.kills %></span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Total Damage Dealt:</span>
            <span class="text-yellow-300 font-bold"><%= @stats.damage_dealt %></span>
          </div>

          <div class="flex justify-between text-green-400">
            <span>Total Health Healed:</span>
            <span class="text-yellow-300 font-bold"><%= @stats.health_healed %></span>
          </div>

          <%= if @stats.monster_breakdown != [] do %>
            <div class="mt-6">
              <h4 class="text-xl text-purple-400 mb-3">Monster Kill Breakdown</h4>
              <div class="space-y-1">
                <%= for {monster_name, count} <- @stats.monster_breakdown do %>
                  <div class="flex justify-between text-green-300">
                    <span><%= monster_name %>:</span>
                    <span class="text-yellow-300"><%= count %></span>
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
            <%= if @show_high_scores, do: "Back to Stats", else: "View High Scores" %>
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
  Start page high scores display component.
  Shows top 10 scores without player highlighting.
  """
  attr :all_scores, :list, required: true

  def start_page_high_scores(assigns) do
    top_10 = Enum.take(assigns.all_scores, 10)
    assigns = assign(assigns, :top_10, top_10)

    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50">
      <div class="bg-gray-800 border-4 border-yellow-500 rounded-lg p-8 max-w-2xl w-full mx-4">
        <h2 class="text-4xl font-bold text-yellow-400 text-center mb-6">High Scores</h2>

        <div class="bg-black p-6 rounded mb-6 space-y-2 font-mono max-h-[500px] overflow-y-auto">
          <%= if @top_10 == [] do %>
            <div class="text-center text-gray-400 py-8">
              No high scores yet. Be the first to play!
            </div>
          <% else %>
            <%= for {score, index} <- Enum.with_index(@top_10, 1) do %>
              <div class="flex justify-between p-2 rounded hover:bg-gray-700 transition-colors">
                <div class="flex gap-4 flex-1">
                  <span class={["w-8 text-right font-bold", rank_color(index)]}><%= index %>.</span>
                  <span class="flex-1"><%= score.name %></span>
                </div>
                <div class="flex gap-6">
                  <span class="text-yellow-400">Lvl <%= score.level %></span>
                  <span class="text-purple-400 w-16 text-right"><%= score.kills %> kills</span>
                </div>
              </div>
            <% end %>
          <% end %>
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
  Shows top 10 scores, highlights player's score if in top 10,
  or shows player's placement if outside top 10.
  """
  attr :all_scores, :list, required: true
  attr :player_name, :string, required: true
  attr :player_level, :integer, required: true
  attr :player_kills, :integer, required: true

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
        <h2 class="text-4xl font-bold text-yellow-400 text-center mb-6">High Scores</h2>

        <div class="bg-black p-6 rounded mb-6 space-y-2 font-mono max-h-[500px] overflow-y-auto">
          <%= for {score, index} <- Enum.with_index(@top_10, 1) do %>
            <div class={[
              "flex justify-between p-2 rounded",
              is_player_score?(score, @player_score, @player_in_top_10) && "bg-green-900 border-2 border-green-400"
            ]}>
              <div class="flex gap-4 flex-1">
                <span class={[
                  "w-8 text-right font-bold",
                  rank_color(index)
                ]}><%= index %>.</span>
                <span class={[
                  "flex-1",
                  is_player_score?(score, @player_score, @player_in_top_10) && "text-green-300 font-bold"
                ]}><%= score.name %></span>
              </div>
              <div class="flex gap-6">
                <span class={[
                  "text-yellow-400",
                  is_player_score?(score, @player_score, @player_in_top_10) && "font-bold"
                ]}>Lvl <%= score.level %></span>
                <span class={[
                  "text-purple-400 w-16 text-right",
                  is_player_score?(score, @player_score, @player_in_top_10) && "font-bold"
                ]}><%= score.kills %> kills</span>
              </div>
            </div>
          <% end %>

          <%= if !@player_in_top_10 do %>
            <div class="mt-6 pt-4 border-t-2 border-gray-600">
              <div class="flex justify-between p-2 rounded bg-blue-900 border-2 border-blue-400">
                <div class="flex gap-4 flex-1">
                  <span class="w-8 text-right font-bold text-blue-300"><%= @player_rank %>.</span>
                  <span class="flex-1 text-blue-200 font-bold">
                    <%= @player_score.name %> (Your Score)
                  </span>
                </div>
                <div class="flex gap-6">
                  <span class="text-yellow-400 font-bold">Lvl <%= @player_score.level %></span>
                  <span class="text-purple-400 font-bold w-16 text-right">
                    <%= @player_score.kills %> kills
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
end
