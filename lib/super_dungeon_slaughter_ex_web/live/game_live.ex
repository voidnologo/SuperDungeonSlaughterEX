defmodule SuperDungeonSlaughterExWeb.GameLive do
  use SuperDungeonSlaughterExWeb, :live_view

  alias SuperDungeonSlaughterEx.Game.GameState
  alias SuperDungeonSlaughterEx.{Score, Repos.ScoreRepo}

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"name" => "", "difficulty" => "normal"}, as: :hero)

    socket =
      socket
      |> assign(:game_state, nil)
      |> assign(:show_name_prompt, true)
      |> assign(:show_high_scores, false)
      |> assign(:form, form)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"hero" => hero_params}, socket) do
    form = to_form(hero_params, as: :hero)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("create_hero", %{"hero" => hero_params}, socket) do
    name =
      if String.trim(hero_params["name"]) == "",
        do: "Hero",
        else: String.trim(hero_params["name"])

    difficulty =
      case hero_params["difficulty"] do
        "easy" -> :easy
        "hard" -> :hard
        _ -> :normal
      end

    game_state = GameState.new(name, difficulty)

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:show_name_prompt, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("fight", _params, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      game_state = GameState.handle_fight(socket.assigns.game_state)
      {:noreply, apply_combat_turn(socket, game_state)}
    end
  end

  @impl true
  def handle_event("rest", _params, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      game_state = GameState.handle_rest(socket.assigns.game_state)
      {:noreply, apply_combat_turn(socket, game_state)}
    end
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    hero_name = socket.assigns.game_state.hero.name
    difficulty = socket.assigns.game_state.difficulty
    game_state = GameState.new(hero_name, difficulty)

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:show_high_scores, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_high_scores", _params, socket) do
    {:noreply, assign(socket, :show_high_scores, !socket.assigns.show_high_scores)}
  end

  @impl true
  def handle_event("show_use_potion_modal", %{"slot" => slot_str}, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      slot_index = String.to_integer(slot_str)
      game_state = GameState.show_use_potion_modal(socket.assigns.game_state, slot_index)
      {:noreply, assign(socket, :game_state, game_state)}
    end
  end

  @impl true
  def handle_event("use_potion", %{"slot" => slot_str}, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      slot_index = String.to_integer(slot_str)
      game_state = GameState.handle_use_potion(socket.assigns.game_state, slot_index)
      {:noreply, apply_combat_turn(socket, game_state)}
    end
  end

  @impl true
  def handle_event("cancel_use_potion", _params, socket) do
    game_state = GameState.close_use_modal(socket.assigns.game_state)
    {:noreply, assign(socket, :game_state, game_state)}
  end

  @impl true
  def handle_event("pickup_potion", %{"slot" => slot_str}, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      slot_index = String.to_integer(slot_str)
      game_state = GameState.handle_pickup_potion(socket.assigns.game_state, slot_index)
      {:noreply, assign(socket, :game_state, game_state)}
    end
  end

  @impl true
  def handle_event("decline_potion", _params, socket) do
    game_state = GameState.handle_decline_potion(socket.assigns.game_state)
    {:noreply, assign(socket, :game_state, game_state)}
  end

  @impl true
  def handle_event("claim_boss_reward", %{"type" => potion_type}, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      game_state = GameState.handle_claim_boss_reward(socket.assigns.game_state, potion_type)
      {:noreply, assign(socket, :game_state, game_state)}
    end
  end

  @impl true
  def handle_event("quit_game", _params, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      # Save score and mark game as over
      save_score(socket.assigns.game_state.hero, socket.assigns.game_state.difficulty)
      game_state = %{socket.assigns.game_state | game_over: true}
      {:noreply, assign(socket, :game_state, game_state)}
    end
  end

  # Assign the post-action state, persist the score on game over, and push any
  # damage/heal numbers to the client so they can float over the hero/enemy.
  defp apply_combat_turn(socket, game_state) do
    if game_state.game_over do
      save_score(game_state.hero, game_state.difficulty)
    end

    socket
    |> assign(:game_state, game_state)
    |> push_combat_popups(game_state.turn_events)
  end

  defp push_combat_popups(socket, [_ | _] = events) do
    push_event(socket, "combat_popups", %{events: events})
  end

  defp push_combat_popups(socket, _events), do: socket

  defp save_score(hero, difficulty) do
    score = Score.new(hero.name, hero.level, hero.total_kills, difficulty)
    ScoreRepo.add_score(score)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <%= if @show_name_prompt do %>
        <div class="flex items-center justify-center min-h-screen p-4">
          <div class="panel panel-studs frame-gold p-8 max-w-md w-full">
            <h1 class="title-pixel text-center leading-tight mb-2">
              <span class="block text-dungeon-gold text-xl sm:text-2xl">SUPER DUNGEON</span>
              <span class="block text-dungeon-blood text-2xl sm:text-3xl mt-2 flicker">
                SLAUGHTER <span class="text-dungeon-gold-bright">EX</span>
              </span>
            </h1>
            <p class="text-center text-dungeon-muted text-base mb-6 tracking-widest">
              ⚔ ⚔ ⚔
            </p>
            <.form for={@form} id="hero-name-form" phx-change="validate" phx-submit="create_hero">
              <div class="space-y-5">
                <div>
                  <label class="label-pixel block text-dungeon-gold text-[11px] mb-2">
                    NAME THY HERO
                  </label>
                  <input
                    type="text"
                    name="hero[name]"
                    id="hero_name"
                    value={Phoenix.HTML.Form.input_value(@form, :name)}
                    placeholder="Enter your name..."
                    autofocus
                    class="w-full px-4 py-3 bg-black border-2 border-dungeon-bevel text-dungeon-heal-bright text-xl focus:outline-none focus:border-dungeon-gold placeholder:text-dungeon-muted"
                  />
                </div>
                <div>
                  <label class="label-pixel block text-dungeon-gold text-[11px] mb-2">
                    CHOOSE DIFFICULTY
                  </label>
                  <div class="grid grid-cols-3 gap-2">
                    <label class={[
                      "relative cursor-pointer border-[3px] p-3 text-center transition-all",
                      (Phoenix.HTML.Form.input_value(@form, :difficulty) == "easy" &&
                         "border-dungeon-mana bg-dungeon-mana/15 shadow-[0_0_14px_rgba(74,168,255,0.5)]") ||
                        "border-black bg-black/40 hover:border-dungeon-mana"
                    ]}>
                      <input
                        type="radio"
                        name="hero[difficulty]"
                        value="easy"
                        checked={Phoenix.HTML.Form.input_value(@form, :difficulty) == "easy"}
                        class="sr-only"
                      />
                      <div class="label-pixel text-dungeon-mana text-[11px]">EASY</div>
                      <div class="text-sm text-dungeon-muted mt-1">-5-10%</div>
                    </label>
                    <label class={[
                      "relative cursor-pointer border-[3px] p-3 text-center transition-all",
                      (Phoenix.HTML.Form.input_value(@form, :difficulty) == "normal" &&
                         "border-dungeon-heal bg-dungeon-heal/15 shadow-[0_0_14px_rgba(87,201,95,0.5)]") ||
                        "border-black bg-black/40 hover:border-dungeon-heal"
                    ]}>
                      <input
                        type="radio"
                        name="hero[difficulty]"
                        value="normal"
                        checked={Phoenix.HTML.Form.input_value(@form, :difficulty) == "normal"}
                        class="sr-only"
                      />
                      <div class="label-pixel text-dungeon-heal text-[11px]">NORMAL</div>
                      <div class="text-sm text-dungeon-muted mt-1">Standard</div>
                    </label>
                    <label class={[
                      "relative cursor-pointer border-[3px] p-3 text-center transition-all",
                      (Phoenix.HTML.Form.input_value(@form, :difficulty) == "hard" &&
                         "border-dungeon-blood bg-dungeon-blood/15 shadow-[0_0_14px_rgba(226,58,78,0.5)]") ||
                        "border-black bg-black/40 hover:border-dungeon-blood"
                    ]}>
                      <input
                        type="radio"
                        name="hero[difficulty]"
                        value="hard"
                        checked={Phoenix.HTML.Form.input_value(@form, :difficulty) == "hard"}
                        class="sr-only"
                      />
                      <div class="label-pixel text-dungeon-blood text-[11px]">HARD</div>
                      <div class="text-sm text-dungeon-muted mt-1">+5-10%</div>
                    </label>
                  </div>
                </div>
                <button type="submit" class="arcade-btn btn-rest w-full py-4 text-sm">
                  BEGIN ADVENTURE
                </button>
                <button
                  type="button"
                  phx-click="toggle_high_scores"
                  class="arcade-btn btn-magic w-full py-4 text-sm"
                >
                  HALL OF HEROES
                </button>
              </div>
            </.form>
          </div>
        </div>
        
    <!-- High Scores Modal from Start Page -->
        <%= if @show_high_scores do %>
          <.start_page_high_scores_all_difficulties all_scores={ScoreRepo.get_all_scores()} />
        <% end %>
      <% else %>
        <!-- Game UI -->
        <header class="text-center py-6 px-4 relative">
          <h1 class="title-pixel leading-tight">
            <span class="text-dungeon-blood text-xl sm:text-3xl">SUPER DUNGEON SLAUGHTER</span>
            <span class="text-dungeon-gold-bright text-xl sm:text-3xl">EX</span>
          </h1>
          <button
            phx-click="quit_game"
            disabled={@game_state.game_over}
            class="arcade-btn btn-stone absolute top-5 right-4 px-4 py-2 text-[10px]"
          >
            QUIT
          </button>
        </header>

        <div id="game-board" phx-hook="CombatShake" class="container mx-auto px-4 pb-8">
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">
            <!-- Game History (spans 2 columns) -->
            <div class="lg:col-span-2">
              <.game_history history={@game_state.history} />
            </div>
            
    <!-- Right sidebar -->
            <div class="space-y-5">
              <!-- Player Stats -->
              <.hero_stats hero={@game_state.hero} />
              <!-- Monster Stats -->
              <.monster_stats monster={@game_state.monster} />
            </div>
          </div>
          
    <!-- Action Buttons -->
          <div class="flex gap-5 justify-center mt-8">
            <button
              phx-click="rest"
              disabled={@game_state.game_over}
              class="arcade-btn btn-rest px-10 py-5 text-base"
            >
              ✚ REST
            </button>
            <button
              phx-click="fight"
              disabled={@game_state.game_over}
              data-shake-trigger
              class="arcade-btn btn-fight px-10 py-5 text-base"
            >
              ⚔ FIGHT
            </button>
          </div>
        </div>
        
    <!-- Potion Use Confirmation Modal -->
        <%= if @game_state.show_potion_use_modal and @game_state.selected_potion do %>
          <.potion_use_modal
            potion={@game_state.selected_potion}
            slot_index={@game_state.selected_potion_slot}
            hero={@game_state.hero}
          />
        <% end %>
        
    <!-- Potion Pickup/Swap Modal -->
        <%= if @game_state.show_potion_pickup_modal and @game_state.pending_potion_drop do %>
          <.potion_pickup_modal
            dropped_potion={@game_state.pending_potion_drop}
            hero={@game_state.hero}
          />
        <% end %>
        
    <!-- Boss Reward Modal -->
        <%= if @game_state.pending_boss_reward do %>
          <.boss_reward_modal current_floor={@game_state.hero.current_floor} />
        <% end %>
        
    <!-- Game Over Modal Overlay -->
        <%= if @game_state.game_over do %>
          <%= if @show_high_scores do %>
            <.high_scores_display
              all_scores={ScoreRepo.get_scores_by_difficulty(@game_state.difficulty)}
              player_name={@game_state.hero.name}
              player_level={@game_state.hero.level}
              player_kills={@game_state.hero.total_kills}
              difficulty={@game_state.difficulty}
            />
          <% else %>
            <.game_over_stats hero={@game_state.hero} show_high_scores={@show_high_scores} />
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
