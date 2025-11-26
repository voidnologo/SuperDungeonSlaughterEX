defmodule SuperDungeonSlaughterExWeb.GameLive do
  use SuperDungeonSlaughterExWeb, :live_view

  alias SuperDungeonSlaughterEx.Game.GameState
  alias SuperDungeonSlaughterEx.{Score, Repos.ScoreRepo}

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"name" => ""}, as: :hero)

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
  def handle_event("create_hero", %{"hero" => %{"name" => name}}, socket) do
    name = if String.trim(name) == "", do: "Hero", else: String.trim(name)
    game_state = GameState.new(name)

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

      # Auto-save score if game over
      socket =
        if game_state.game_over do
          save_score(game_state.hero)
          assign(socket, :game_state, game_state)
        else
          assign(socket, :game_state, game_state)
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("rest", _params, socket) do
    if socket.assigns.game_state.game_over do
      {:noreply, socket}
    else
      game_state = GameState.handle_rest(socket.assigns.game_state)

      # Auto-save score if game over
      socket =
        if game_state.game_over do
          save_score(game_state.hero)
          assign(socket, :game_state, game_state)
        else
          assign(socket, :game_state, game_state)
        end

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    hero_name = socket.assigns.game_state.hero.name
    game_state = GameState.new(hero_name)

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

  defp save_score(hero) do
    score = Score.new(hero.name, hero.level, hero.total_kills)
    ScoreRepo.add_score(score)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-green-400 font-mono">
      <%= if @show_name_prompt do %>
        <div class="flex items-center justify-center min-h-screen">
          <div class="bg-gray-800 border-4 border-orange-500 rounded-lg p-8 max-w-md w-full mx-4">
            <h2 class="text-3xl font-bold text-red-500 text-center mb-6">
              Super Dungeon Slaughter EX
            </h2>
            <.form for={@form} id="hero-name-form" phx-change="validate" phx-submit="create_hero">
              <div class="space-y-4">
                <div>
                  <label class="block text-green-400 mb-2">What is your hero's name?</label>
                  <input
                    type="text"
                    name="hero[name]"
                    id="hero_name"
                    value={Phoenix.HTML.Form.input_value(@form, :name)}
                    placeholder="Enter your name..."
                    autofocus
                    class="w-full px-4 py-2 bg-black border-2 border-green-500 text-green-400 rounded focus:outline-none focus:border-green-300"
                  />
                </div>
                <button
                  type="submit"
                  class="w-full py-3 bg-green-600 hover:bg-green-700 text-white text-xl font-bold rounded transition-colors"
                >
                  Begin Adventure
                </button>
                <button
                  type="button"
                  phx-click="toggle_high_scores"
                  class="w-full py-3 bg-purple-600 hover:bg-purple-700 text-white text-xl font-bold rounded transition-colors"
                >
                  View High Scores
                </button>
              </div>
            </.form>
          </div>
        </div>
        
    <!-- High Scores Modal from Start Page -->
        <%= if @show_high_scores do %>
          <.start_page_high_scores all_scores={ScoreRepo.get_all_scores()} />
        <% end %>
      <% else %>
        <!-- Game UI -->
        <header class="text-center py-6">
          <h1 class="text-4xl font-bold text-red-500 drop-shadow-lg">
            Super Dungeon Slaughter EX
          </h1>
        </header>

        <div class="container mx-auto px-4 pb-8">
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <!-- Game History (spans 2 columns) -->
            <div class="lg:col-span-2">
              <.game_history history={@game_state.history} />
            </div>
            
    <!-- Right sidebar -->
            <div class="space-y-4">
              <!-- Player Stats -->
              <.hero_stats hero={@game_state.hero} />
              <!-- Monster Stats -->
              <.monster_stats monster={@game_state.monster} />
            </div>
          </div>
          
    <!-- Action Buttons -->
          <div class="flex gap-4 justify-center mt-8">
            <button
              phx-click="rest"
              disabled={@game_state.game_over}
              class="px-8 py-4 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-2xl font-bold rounded-lg transition-colors shadow-lg"
            >
              REST
            </button>
            <button
              phx-click="fight"
              disabled={@game_state.game_over}
              class="px-8 py-4 bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-2xl font-bold rounded-lg transition-colors shadow-lg"
            >
              FIGHT
            </button>
          </div>
        </div>
        
    <!-- Game Over Modal Overlay -->
        <%= if @game_state.game_over do %>
          <%= if @show_high_scores do %>
            <.high_scores_display
              all_scores={ScoreRepo.get_all_scores()}
              player_name={@game_state.hero.name}
              player_level={@game_state.hero.level}
              player_kills={@game_state.hero.total_kills}
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
