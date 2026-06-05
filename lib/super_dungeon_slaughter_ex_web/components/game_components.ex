defmodule SuperDungeonSlaughterExWeb.GameComponents do
  @moduledoc """
  Game-specific UI components for Super Dungeon Slaughter EX.

  Styling follows the 16-bit pixel-arcade design system defined in
  `assets/css/app.css` (`.panel`, `.arcade-btn`, `.gauge`, `.inv-slot`, …).
  """

  use Phoenix.Component
  alias SuperDungeonSlaughterEx.Game.{Hero, Monster, Potion}
  alias SuperDungeonSlaughterEx.Score

  @doc """
  Game history display component showing scrollable combat log with icons and colors.
  """
  attr :history, :list, required: true

  def game_history(assigns) do
    ~H"""
    <div class="panel panel-studs frame-gold h-[600px] flex flex-col">
      <div class="label-pixel text-dungeon-gold text-[11px] px-4 py-3 bg-black/40 border-b-2 border-black flex items-center gap-2">
        <span class="text-base">⚔</span> BATTLE LOG
      </div>
      <div
        id="game-history"
        phx-hook="ScrollToBottom"
        class="flex-1 overflow-y-auto p-4 bg-black/50 pixel-scroll"
      >
        <div class="space-y-1 combat-log">
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
    </div>
    """
  end

  @doc """
  Hero stats panel component with integrated inventory display.
  """
  attr :hero, :map, required: true

  def hero_stats(assigns) do
    ~H"""
    <div id="hero-panel" class="panel panel-studs frame-gold p-5">
      <h2 class="label-pixel text-dungeon-gold text-sm mb-4 flex items-center gap-2">
        <span>🛡</span> HERO
      </h2>
      <div class="space-y-2 text-lg">
        <div class="flex justify-between items-baseline">
          <span class="text-dungeon-muted">Name</span>
          <span class="text-dungeon-gold-bright font-bold">{@hero.name}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="text-dungeon-muted">Floor</span>
          <span class="text-dungeon-xp">{@hero.current_floor}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="text-dungeon-muted">Kills</span>
          <span class="text-dungeon-gold-bright">{@hero.total_kills}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="text-dungeon-muted">Level</span>
          <span class="label-pixel text-dungeon-gold-bright text-sm">{@hero.level}</span>
        </div>
        <div class="pt-1">
          <div class="flex justify-between mb-1 text-sm">
            <span class="text-dungeon-muted">XP</span>
            <span class="text-dungeon-xp">
              {elem(Hero.level_progress(@hero), 0)}/{elem(Hero.level_progress(@hero), 1)}
            </span>
          </div>
          <.level_progress_bar hero={@hero} />
        </div>
        <div class="pt-1">
          <div class="flex justify-between mb-1">
            <span class="text-dungeon-muted">HP</span>
            <span class={["font-bold", hp_color(@hero)]}>{@hero.hp}/{@hero.hp_max}</span>
          </div>
          <.hp_bar percentage={Hero.hp_percentage(@hero)} />
        </div>
        <div class="flex justify-between text-base pt-1">
          <span class="text-dungeon-muted">⚔ Damage</span>
          <span class="text-dungeon-parchment">{@hero.damage_min}-{@hero.damage_max}</span>
        </div>
        <div class="flex justify-between text-base">
          <span class="text-dungeon-muted">✚ Heal</span>
          <span class="text-dungeon-parchment">{@hero.heal_min}-{@hero.heal_max}</span>
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
    <div
      id="enemy-panel"
      class={[
        "panel panel-studs p-5",
        (@monster.is_boss && "frame-blood boss-pulse") || "frame-magic"
      ]}
    >
      <h2 class={[
        "label-pixel mb-4 flex items-center gap-2",
        (@monster.is_boss && "text-dungeon-blood text-sm flicker") || "text-dungeon-magic text-xs"
      ]}>
        <%= if @monster.is_boss do %>
          <span class="blink">⚔</span> BOSS FIGHT <span class="blink">⚔</span>
        <% else %>
          <span>👹</span> ENEMY
        <% end %>
      </h2>
      <div class="space-y-3">
        <div class={[
          "text-2xl font-bold float",
          (@monster.is_boss && "text-dungeon-blood") || "text-dungeon-magic"
        ]}>
          {@monster.display_name}
        </div>
        <div>
          <div class="flex justify-between mb-1 text-lg">
            <span class="text-dungeon-muted">HP</span>
            <span class={["font-bold", hp_color(@monster)]}>{@monster.hp}/{@monster.hp_max}</span>
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
    <div class="gauge h-5">
      <div
        class={["gauge-fill", gauge_hp_class(@percentage)]}
        style={"width: #{@percentage * 100}%"}
      />
    </div>
    """
  end

  @doc """
  Level progress bar component showing kills until next level.
  """
  attr :hero, :map, required: true

  def level_progress_bar(assigns) do
    {current_kills, kills_needed} = Hero.level_progress(assigns.hero)
    percentage = if kills_needed > 0, do: current_kills / kills_needed, else: 0.0
    assigns = assign(assigns, :percentage, percentage)

    ~H"""
    <div class="gauge h-3">
      <div class="gauge-fill gauge-xp" style={"width: #{@percentage * 100}%"} />
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
    <div class="mt-5 pt-4 border-t-2 border-black">
      <h3 class="label-pixel text-dungeon-gold text-[11px] mb-3 flex items-center gap-2">
        <span>🎒</span> SATCHEL
      </h3>
      <div class="grid grid-cols-5 gap-2">
        <%= for {slot, index} <- Enum.with_index(@inventory.slots) do %>
          <%= if slot do %>
            <button
              phx-click="show_use_potion_modal"
              phx-value-slot={index}
              class="inv-slot inv-slot-filled"
              title={slot.display_name}
            >
              <span class={[Potion.get_color_class(slot), Potion.get_icon_size_class(slot)]}>
                {Potion.get_icon(slot)}
              </span>
            </button>
          <% else %>
            <div class="inv-slot inv-slot-empty"></div>
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
          "Throw at monster (deals #{get_percentage_text(assigns.potion.quality)} of monster's max HP)"
      end

    assigns = assign(assigns, :effect_description, effect_description)

    ~H"""
    <div class="modal-scrim">
      <div class="panel panel-studs frame-magic modal-pop p-6 max-w-md w-full mx-4">
        <h2 class="label-pixel text-dungeon-magic text-sm text-center mb-5">USE POTION?</h2>

        <div class="bg-black/50 border-2 border-black p-6 mb-5 flex flex-col items-center">
          <span class={[Potion.get_color_class(@potion), "text-6xl mb-3 float"]}>
            {Potion.get_icon(@potion)}
          </span>
          <div class={["text-xl font-bold mb-2", Potion.get_color_class(@potion)]}>
            {@potion.display_name}
          </div>
          <div class="text-dungeon-parchment text-center text-base">
            {@effect_description}
          </div>
        </div>

        <div class="flex gap-3">
          <button phx-click="cancel_use_potion" class="arcade-btn btn-stone flex-1 py-3 text-xs">
            CANCEL
          </button>
          <button
            phx-click="use_potion"
            phx-value-slot={@slot_index}
            class="arcade-btn btn-rest flex-1 py-3 text-xs"
          >
            USE IT!
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
    <div class="modal-scrim">
      <div class="panel panel-studs frame-gold modal-pop p-6 max-w-lg w-full mx-4">
        <h2 class="label-pixel text-dungeon-gold text-sm text-center mb-5">SATCHEL FULL!</h2>

        <p class="text-center text-dungeon-parchment mb-4 text-lg">
          A potion dropped, but your satchel is full. Swap one out?
        </p>

        <div class="bg-black/50 border-2 border-black p-4 flex flex-col items-center mb-5">
          <span class={[Potion.get_color_class(@dropped_potion), "text-5xl mb-2 float"]}>
            {Potion.get_icon(@dropped_potion)}
          </span>
          <div class={["font-bold text-lg", Potion.get_color_class(@dropped_potion)]}>
            {@dropped_potion.display_name}
          </div>
        </div>

        <h3 class="label-pixel text-dungeon-gold text-[11px] mb-3">YOUR SATCHEL</h3>
        <div class="grid grid-cols-5 gap-2 mb-5">
          <%= for {slot, index} <- Enum.with_index(@hero.inventory.slots) do %>
            <%= if slot do %>
              <button
                phx-click="pickup_potion"
                phx-value-slot={index}
                class="inv-slot inv-slot-filled"
                title={"Replace with #{slot.display_name}"}
              >
                <span class={[Potion.get_color_class(slot), Potion.get_icon_size_class(slot)]}>
                  {Potion.get_icon(slot)}
                </span>
              </button>
            <% end %>
          <% end %>
        </div>

        <button phx-click="decline_potion" class="arcade-btn btn-fight w-full py-3 text-xs">
          LEAVE IT BEHIND
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
    <div class="modal-scrim">
      <div class="panel panel-studs frame-gold modal-pop p-8 max-w-md w-full mx-4">
        <h2 class="title-pixel text-dungeon-gold text-xl text-center mb-4 flicker">
          BOSS DEFEATED!
        </h2>

        <p class="text-dungeon-heal text-center mb-6 text-lg">
          You have conquered Floor {@current_floor}!<br /> Your wounds heal as you rest.
        </p>

        <div class="bg-black/50 border-2 border-black p-5 mb-6">
          <h3 class="label-pixel text-dungeon-magic text-xs mb-4 text-center">CHOOSE YOUR REWARD</h3>
          <div class="flex gap-4 justify-center">
            <button
              phx-click="claim_boss_reward"
              phx-value-type="healing"
              class="arcade-btn btn-rest flex-1 px-4 py-4 flex-col gap-2 text-[10px]"
            >
              <span class="text-4xl">🏺</span> MAJOR<br />HEALING
            </button>
            <button
              phx-click="claim_boss_reward"
              phx-value-type="damage"
              class="arcade-btn btn-fight flex-1 px-4 py-4 flex-col gap-2 text-[10px]"
            >
              <span class="text-4xl">🏺</span> MAJOR<br />DAMAGE
            </button>
          </div>
        </div>

        <p class="text-dungeon-muted text-base text-center italic">
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
    <div class="modal-scrim">
      <div class="panel panel-studs frame-blood modal-pop p-8 max-w-2xl w-full mx-4">
        <h2 class="title-pixel text-dungeon-blood text-3xl text-center mb-6 flicker">GAME OVER</h2>

        <div class="bg-black/50 border-2 border-black p-6 mb-6 space-y-3 combat-log max-h-[500px] overflow-y-auto pixel-scroll">
          <h3 class="label-pixel text-dungeon-gold text-xs mb-4">FINAL STATISTICS</h3>

          <div class="flex justify-between text-dungeon-heal text-lg">
            <span>Level Achieved</span>
            <span class="text-dungeon-gold-bright font-bold">{@stats.level}</span>
          </div>

          <div class="flex justify-between text-dungeon-heal text-lg">
            <span>Monsters Killed</span>
            <span class="text-dungeon-gold-bright font-bold">{@stats.kills}</span>
          </div>

          <div class="flex justify-between text-dungeon-heal text-lg">
            <span>Total Damage Dealt</span>
            <span class="text-dungeon-gold-bright font-bold">{@stats.damage_dealt}</span>
          </div>

          <div class="flex justify-between text-dungeon-heal text-lg">
            <span>Total Health Healed</span>
            <span class="text-dungeon-gold-bright font-bold">{@stats.health_healed}</span>
          </div>

          <%= if @stats.monster_breakdown != [] do %>
            <div class="mt-6">
              <h4 class="label-pixel text-dungeon-magic text-[11px] mb-3">SLAIN FOES</h4>
              <div class="space-y-1">
                <%= for {monster_name, count} <- @stats.monster_breakdown do %>
                  <div class="flex justify-between text-dungeon-heal-bright text-lg">
                    <span>{monster_name}</span>
                    <span class="text-dungeon-gold-bright">{count}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex gap-4">
          <button
            phx-click="toggle_high_scores"
            class="arcade-btn btn-magic flex-1 py-4 text-xs"
          >
            {if @show_high_scores, do: "BACK TO STATS", else: "HIGH SCORES"}
          </button>
          <button phx-click="new_game" class="arcade-btn btn-rest flex-1 py-4 text-xs">
            NEW GAME
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
    <div class="modal-scrim overflow-y-auto">
      <div class="panel panel-studs frame-gold modal-pop p-8 max-w-4xl w-full mx-4 my-8">
        <h2 class="title-pixel text-dungeon-gold text-2xl text-center mb-6 flicker">
          HALL OF HEROES
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <.score_column title="EASY" accent="text-dungeon-mana" scores={@easy_scores} />
          <.score_column title="NORMAL" accent="text-dungeon-heal" scores={@normal_scores} />
          <.score_column title="HARD" accent="text-dungeon-blood" scores={@hard_scores} />
        </div>

        <button phx-click="toggle_high_scores" class="arcade-btn btn-magic w-full py-4 text-xs">
          BACK
        </button>
      </div>
    </div>
    """
  end

  # Single difficulty column for the start-page leaderboard.
  attr :title, :string, required: true
  attr :accent, :string, required: true
  attr :scores, :list, required: true

  defp score_column(assigns) do
    ~H"""
    <div class="bg-black/50 border-2 border-black p-4">
      <h3 class={["label-pixel text-center mb-3 text-xs", @accent]}>{@title}</h3>
      <div class="space-y-1 combat-log max-h-[300px] overflow-y-auto pixel-scroll">
        <%= if @scores == [] do %>
          <div class="text-center text-dungeon-muted py-4 text-base">No scores yet</div>
        <% else %>
          <%= for {score, index} <- Enum.with_index(@scores, 1) do %>
            <div class="flex justify-between p-1 text-base">
              <div class="flex gap-2 min-w-0">
                <span class={["w-5 text-right", rank_color(index)]}>{index}.</span>
                <span class="truncate">{score.name}</span>
              </div>
              <div class="flex gap-2 flex-shrink-0">
                <span class="text-dungeon-gold">L{score.level}</span>
                <span class="text-dungeon-magic">{score.kills}</span>
              </div>
            </div>
          <% end %>
        <% end %>
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
    <div class="modal-scrim">
      <div class="panel panel-studs frame-gold modal-pop p-8 max-w-2xl w-full mx-4">
        <h2 class="title-pixel text-dungeon-gold text-2xl text-center mb-2 flicker">
          HALL OF HEROES
        </h2>
        <div class={["label-pixel text-sm text-center mb-5", difficulty_color(@difficulty)]}>
          {difficulty_label(@difficulty)}
        </div>

        <div class="bg-black/50 border-2 border-black p-6 mb-6 space-y-2 combat-log max-h-[500px] overflow-y-auto pixel-scroll">
          <%= for {score, index} <- Enum.with_index(@top_10, 1) do %>
            <div class={[
              "flex justify-between p-2 text-lg",
              is_player_score?(score, @player_score, @player_in_top_10) &&
                "bg-dungeon-heal/20 border-2 border-dungeon-heal"
            ]}>
              <div class="flex gap-4 flex-1 min-w-0">
                <span class={["w-8 text-right font-bold", rank_color(index)]}>{index}.</span>
                <span class={[
                  "flex-1 truncate",
                  is_player_score?(score, @player_score, @player_in_top_10) &&
                    "text-dungeon-heal-bright font-bold"
                ]}>
                  {score.name}
                </span>
              </div>
              <div class="flex gap-6 flex-shrink-0">
                <span class="text-dungeon-gold">Lv {score.level}</span>
                <span class="text-dungeon-magic w-16 text-right">{score.kills} kills</span>
              </div>
            </div>
          <% end %>

          <%= if !@player_in_top_10 do %>
            <div class="mt-6 pt-4 border-t-2 border-black">
              <div class="flex justify-between p-2 text-lg bg-dungeon-mana/20 border-2 border-dungeon-mana">
                <div class="flex gap-4 flex-1 min-w-0">
                  <span class="w-8 text-right font-bold text-dungeon-mana">{@player_rank}.</span>
                  <span class="flex-1 truncate text-dungeon-mana font-bold">
                    {@player_score.name} (You)
                  </span>
                </div>
                <div class="flex gap-6 flex-shrink-0">
                  <span class="text-dungeon-gold font-bold">Lv {@player_score.level}</span>
                  <span class="text-dungeon-magic font-bold w-16 text-right">
                    {@player_score.kills} kills
                  </span>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex gap-4">
          <button phx-click="toggle_high_scores" class="arcade-btn btn-magic flex-1 py-4 text-xs">
            BACK TO STATS
          </button>
          <button phx-click="new_game" class="arcade-btn btn-rest flex-1 py-4 text-xs">
            NEW GAME
          </button>
        </div>
      </div>
    </div>
    """
  end

  # Helper Functions

  defp gauge_hp_class(percentage) when percentage > 0.66, do: "gauge-hp-high"
  defp gauge_hp_class(percentage) when percentage > 0.33, do: "gauge-hp-mid"
  defp gauge_hp_class(_), do: "gauge-hp-low"

  defp hp_color(%{hp: hp, hp_max: max}) when max > 0 do
    percentage = hp / max
    hp_color_by_percentage(percentage)
  end

  defp hp_color(_), do: "text-dungeon-blood"

  defp hp_color_by_percentage(percentage) when percentage > 0.66, do: "text-dungeon-heal-bright"
  defp hp_color_by_percentage(percentage) when percentage > 0.33, do: "text-dungeon-gold"
  defp hp_color_by_percentage(_), do: "text-dungeon-blood"

  defp rank_color(1), do: "text-dungeon-gold-bright"
  defp rank_color(2), do: "text-dungeon-parchment"
  defp rank_color(3), do: "text-dungeon-gold"
  defp rank_color(_), do: "text-dungeon-muted"

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
  defp difficulty_color(:easy), do: "text-dungeon-mana"
  defp difficulty_color(:hard), do: "text-dungeon-blood"
  defp difficulty_color(_), do: "text-dungeon-heal"
end
