defmodule SubtleWeb.SubtleLive do
  use SubtleWeb, :live_view
  use Phoenix.Component
  alias Subtle.{Game, Puzzle}
  alias SubtleWeb.SubtleComponents

  def mount(_params, session, socket) do
#    puzzle = Puzzle.new()
#    puzzle = Puzzle.new("paper")
#    {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
#    {:ok, puzzle} = Puzzle.make_guess(puzzle, "poppy")

    {:ok, assign(socket,
                  page_title: "Subtle",
                  session_id: session["live_socket_id"],
                  game: Game.new(),
                  message: "Subtle"
                )}
  end

  def render(assigns) do
# put after <div relative
#    <Heroicons.cog_8_tooth mini class="absolute top-5 right-5 w-6 h-6 fill-zinc-200"
#    phx-click={show_modal("settings-modal-id")} />
    ~H"""
    <h2 class="text-2xl text-zinc-200 mb-4">
      <%= @message %>
    </h2>
    <div class="grid grid-flow-row gap-y-4">
      <div class="relative flex rounded-lg p-2 bg-slate-700/50">
        <.modal id="settings-modal-id">
          <p>Inner Modal Content</p>
          <form id="settings_form" phx-submit="save">
          </form>
        </.modal>

        <%= if Game.state(@game) == :playing do %>
          <.guess_form message={Game.message(@game)} verify={@game.verify_guesses} />
        <% else %>
          <.game_over message={Game.message(@game)} answer={Game.answer(@game)} />
        <% end %>
      </div>

      <%= render_guesses(assigns) %>
      <%= render_legend(assigns) %>
      </div>
    """
#    <p class="mt-30 text-zinc-200"> <%= Game.summary @game %> </p>
  end

  attr :message, :string, default: ""
  attr :value, :string, default: ""
  attr :verify, :boolean, default: true
  attr :errors, :list, default: []

  def guess_form(assigns) do
#    IO.puts("guess_form.assigns")
#    IO.inspect(assigns)
    ~H"""
    <form id="guess_form" phx-submit="guess">
      <div class="p-4 space-y-4">
        <label class="block text-xl font-medium text-zinc-200">
          <%= @message %>
        </label>
        <div class="flex space-x-4 auto-rows-max items-center">
          <input type="text" name="guess"
            autofocus autocomplete="off"
            value={Phoenix.HTML.Form.normalize_value("text", @value)}
            class={[
              "block w-full rounded-lg text-zinc-900 sm:text-sm sm:leading-6",
              "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
              "border-zinc-300 focus:border-zinc-400",
              @errors != [] && "border-rose-400 focus:border-rose-400"
            ]}
          />
          <.button>Guess</.button>
        </div>
        <label class="flex items-center gap-4 leading-6 text-sm md:text-base text-zinc-200">
          <input type="checkbox" name="verify" value="true" checked={@verify} />
          Require guess to be in the dictionary
        </label>
      </div>
    </form>
    """
#<input type="checkbox" name="prices[]" value={price} id={price}
#   checked={price in @filter.prices} />
#<label for={price}><%= price %></label>
#
#<.input type="checkbox" name="dictionary"
#label="Require guess to be in the dictionary"
#checked="true" value="true" class="text-zinc-200" />

  end

  attr :message, :string, required: true
  attr :answer, :string, required: true

  def game_over(assigns) do
    ~H"""
    <div class="flex items-center space-x-10">
      <p class="text-2xl text-zinc-200">
        <%= @message <> "  The word was " <> @answer <> "." %>
      </p>
      <.button phx-click="new_game">New Game</.button>
    </div>
    """
  end

  attr :game, :map, required: true
  def render_guesses(assigns) do
#    IO.inspect(Puzzle.normalized_guesses(assigns.puzzle))
    ~H"""
    <div class="flex rounded-lg p-4 bg-slate-700/50">
      <div class="grid grid-flow-row auto-rows-max gap-y-2 md:gap-y-4">
        <%= for guess <- Game.guesses(@game) do %>
          <%= render_guess guess %>
        <% end %>
        <p class="text-zinc-200 ml-3"> <%= Game.guesses_remaining(@game) %> guesses remaining </p>
        <SubtleComponents.show_letters_used letters={Game.letters_used(@game)} />
      </div>
    </div>
    """
  end

  attr :results, :list, required: true

  def render_guess(assigns) do
#    IO.inspect(assigns)
    ~H"""
    <div class="guessrow">
      <%= for {letter, hint} = _result <- @results do %>
        <SubtleComponents.letter_box kind={:guess} letter={letter} hint={hint}/>
      <% end %>
    </div>
    """
  end

  def render_legend(assigns) do
    ~H"""
    <div class="flex rounded-lg p-4 bg-slate-700/50 grid grid-flow-row auto-rows-min gap-y-2">
      <h1 class="text-xl font-medium text-zinc-200">Legend:</h1>
      <.render_legend_key letter="!" hint={:correct} description="Correct letter" />
      <.render_legend_key letter="?" hint={:wrong_position} description="Good letter, wrong location" />
      <.render_legend_key letter="x" hint={:wrong_letter} description="Letter not in puzzle" />
    </div>
    """
  end

  def render_legend_key(assigns) do
    ~H"""
    <div class="flex justify-after items-center space-x-4">
      <SubtleComponents.letter_box kind={:key} letter={@letter} hint={@hint}/>
      <p class="text-left text-base md:text-lg font-medium text-zinc-200">
        <%= @description %>
      </p>
    </div>
    """
  end

  def handle_event("guess", %{"guess" => guess} = params, socket) do
    guess =
      guess
      |> String.trim
      |> String.downcase

#    verify = Map.get(params, "verify", false) == "true"
    verify = !!Map.get(params, "verify", false) # !! hack gets us true/false
    game = %{socket.assigns.game | verify_guesses: verify}
#    IO.inspect(guess, label: "guess")
#    IO.inspect(verify, label: "verify")
#    IO.inspect(game)

    with {:ok, game} <- Game.make_guess(game, guess) do
      {:noreply, assign(socket, game: game)}
    else
      # opportunity to set some error assigns
      {:error, game} ->
        {:noreply, assign(socket, game: game)}
    end
  end

  def handle_event("new_game", _params, socket) do
    {:noreply, assign(socket, game: Game.new())}
  end

end
