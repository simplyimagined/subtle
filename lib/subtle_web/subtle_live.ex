defmodule SubtleWeb.SubtleLive do
  use SubtleWeb, :live_view
  use Phoenix.Component
  import SubtleWeb.SubtleComponents
  alias Subtle.Game
  alias SubtleWeb.SubtleComponents

  def mount(_params, session, socket) do
    {:ok, assign(socket,
                  page_title: "Subtle",
                  session_id: session["live_socket_id"],
                  game: Game.new(),
                  message: "Subtle",
                  settings: to_form(%{verify: true})
                )}
  end

  def render(assigns) do
#<h2 class="text-2xl text-zinc-200 mb-4">
#<%= @message %>
#</h2>
    #    <Heroicons.cog_8_tooth mini class="absolute top-5 right-5 w-6 h-6 fill-zinc-200"
#    phx-click={show_modal("settings-modal-id")} />
    ~H"""
    <div class="app_header">
      <div class="flex justify-start gap-x-2">
        <.hero_modal_button modal_id="legend-modal" icon="hero-list-bullet" />
        <.hero_modal_button modal_id="help-modal" icon="hero-question-mark-circle" />
      </div>
      <h1>Subtle</h1>
      <div class="flex justify-end gap-x-2">
        <.hero_modal_button modal_id="quit-modal" icon="hero-face-frown" />
        <.hero_modal_button modal_id="settings-modal" icon="hero-cog-6-tooth" />
      </div>
    </div>

    <.subtle_modal id="legend-modal">
      <%= legend(assigns) %>
    </.subtle_modal>
    <.subtle_modal id="help-modal">
      <div class="possible_words">
        <h1>Possible words:</h1>
        <p><%= available_answers(@game) %></p>
      </div>
    </.subtle_modal>
    <.subtle_modal id="quit-modal">
      <form class="give_up" phx-submit="give_up">
        <h1>Game over, man!</h1>
        <p>I tried really, really hard but this isn't working out for me. I'd like to quit the gym.</p>
        <.button phx-click={hide_modal("quit-modal")}>
          I give up
          <.icon name="hero-face-frown-mini" class="ml-1 w-6 h-6" />
        </.button>
      </form>
    </.subtle_modal>
    <.modal id="settings-modal">
      <.form for={@settings} phx-submit="settings">
        <.input type="checkbox" id="settings-verify"
            field={@settings[:verify]}
            label="Require guess to be in the dictionary"
            checked={@game.verify_guesses} />
        <p>&nbsp;</p>
        <.button phx-click={hide_modal("settings-modal")}>
          Save
        </.button>
      </.form>
    </.modal>


    <div class="grid grid-flow-row gap-y-4">
      <div class="relative flex rounded-lg p-2 bg-slate-700/50">

        <%= if Game.state(@game) == :playing do %>
          <.guess_form message={Game.message(@game)} verify={@game.verify_guesses} />
        <% else %>
          <.game_over message={Game.message(@game)} answer={Game.answer(@game)} />
        <% end %>
      </div>

      <%= render_guesses(assigns) %>

    </div>
    """
#      <%= render_legend(assigns) %>
      #    <p class="mt-30 text-zinc-200"> <%= Game.summary @game %> </p>
  end

  attr :message, :string, default: ""
  attr :value, :string, default: ""
  attr :verify, :boolean, default: true
  attr :errors, :list, default: []

  def guess_form(assigns) do
#    IO.puts("guess_form.assigns")
#    IO.inspect(assigns)
#me <div class="flex space-x-4 auto-rows-max items-center">
#them <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
    ~H"""
    <form id="guess_form" phx-submit="guess">
      <div class="p-4 space-y-4">
        <label class="block text-xl font-medium text-zinc-200">
          <%= @message %>
        </label>
        <div class="flex items-center justify-between space-x-4">
          <input type="text" id="guess" name="guess"
            autofocus autocomplete="off"
            value={Phoenix.HTML.Form.normalize_value("text", @value)}
            class={[
              "block w-full rounded-lg text-zinc-900",
              "text-md md:text-xl leading-4 md:leading-6",
              "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
              "border-zinc-300 focus:border-zinc-400",
              @errors != [] && "border-rose-400 focus:border-rose-400"
            ]}
          />
          <.button class="whitespace-nowrap">
            Guess
            <.icon name="hero-question-mark-circle-mini" class="ml-1 w-6 h-6" />
          </.button>
        </div>
      </div>
    </form>
    """
  end

  attr :message, :string, required: true
  attr :answer, :string, required: true

  def game_over(assigns) do
    ~H"""
    <div class="flex items-center space-x-10">
      <p class="text-2xl text-zinc-200">
        <%= @message <> "  The word was \u201C" <> String.upcase(@answer) <> "\u201D." %>
      </p>
      <.button phx-click="new_game">New Game</.button>
    </div>
    """
  end

  attr :game, :map, required: true
  def render_guesses(assigns) do
#    IO.inspect(Puzzle.normalized_guesses(assigns.puzzle))
    ~H"""
    <div class="flex rounded-lg p-4 justify-center bg-slate-700/50">
      <div class="grid grid-flow-row justify-center auto-rows-max gap-y-2 md:gap-y-4">
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

  def legend(assigns) do
    ~H"""
    <div class="legend">
      <h1>Legend:</h1>
      <div class="legend_groups">
        <div class="legend_group">
          <h2>Guesses</h2>
          <.legend_key letter="!" hint={:correct} description="Correct letter" />
          <.legend_key letter="?" hint={:wrong_position} description="Good letter, wrong location" />
          <.legend_key letter="x" hint={:wrong_letter} description="Letter not in answer" />
        </div>
        <div class="legend_group">
          <h2>Letters used</h2>
          <.legend_key letter="x" hint={:used} description="Somewhere in puzzle" />
          <.legend_key letter="x" hint={:wrong_letter} description="Letter not in answer" />
          <.legend_key letter="x" hint={:unused} description="Not guessed yet" />
        </div>
      </div>
    </div>
    """
  end

  def legend_key(assigns) do
    ~H"""
    <div class="legend_key">
      <SubtleComponents.letter_box kind={:key} letter={@letter} hint={@hint}/>
      <p class="desc"> <%= @description %> </p>
    </div>
    """
  end

  def available_answers(game) do
    answers = Game.available_words_as_string(game, 20)
    if answers == "" do
      "You haven't made a guess yet!"
    else
      answers
    end
  end

  def handle_event("guess", %{"guess" => guess}, socket) do
    guess =
      guess
      |> String.trim
      |> String.downcase

    # !! hack gets us true/false from nil, "true"
#    verify = !!Map.get(params, "verify", false)
#    game = %{socket.assigns.game | verify_guesses: verify}
    game = socket.assigns.game
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

  def handle_event("settings", %{"verify" => verify} = _params, socket) do
    game = Game.set_verify(socket.assigns.game, to_boolean(verify))
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("new_game", _params, socket) do
    {:noreply, assign(socket, game: Game.new())}
  end

  def handle_event("give_up", _params, socket) do
    {:noreply, assign(socket, game: Game.game_over_man(socket.assigns.game))}
  end

  defp to_boolean("true"), do: true
  defp to_boolean(_), do: false

end
