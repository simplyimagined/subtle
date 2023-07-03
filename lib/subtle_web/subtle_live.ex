defmodule SubtleWeb.SubtleLive do
  use SubtleWeb, :live_view
  use Phoenix.Component
  alias Subtle.Puzzle

  def mount(_params, session, socket) do
    puzzle = Puzzle.new()
#    puzzle = Puzzle.new("paper")
#    {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
#    {:ok, puzzle} = Puzzle.make_guess(puzzle, "poppy")
    form = to_form(%{"guess" => ""})

    {:ok, assign(socket,
                  page_title: "Subtle",
                  session_id: session["live_socket_id"],
                  puzzle: puzzle,
                  message: "Subtle",
                  show_settings: false,
                  form: form )}
  end

  def render(assigns) do
#    <div class="absolute top-6 right-5">
#    <Heroicons.cake solid class="w-2 h-2" />
#      <button phx-click="settings">
#        <.icon name="hero-cog-6-tooth" class="w-6 h-6 bg-zinc-200" />
#      </button>
#    </div>

    ~H"""
    <h2 class="text-2xl text-zinc-200 mb-4">
      <%= @message %>
    </h2>
    <div class="grid grid-flow-row gap-y-4">
      <div class="relative flex rounded-lg p-2 bg-slate-700/50">
        <Heroicons.cog_8_tooth mini class="absolute top-5 right-5 w-6 h-6 fill-zinc-200"
          phx-click={show_modal("settings-modal-id")} />
        <.modal id="settings-modal-id">
           <p>Inner Modal Content</p>
        </.modal>

        <%= if @puzzle.state == :playing do %>
          <.guess_form message={@puzzle.message} />
        <% else %>
          <.game_over message={@puzzle.message} answer={@puzzle.answer} />
        <% end %>
      </div>

      <%= render_guesses(assigns) %>
      <%= render_legend(assigns) %>
    </div>
    <p class="mt-50 text-zinc-200"> <%= Puzzle.summary @puzzle %> </p>
    """
end

  attr :message, :string, default: ""
  attr :value, :string, default: ""
  attr :errors, :list, default: []

  def guess_form(assigns) do
#    IO.puts("guess_form.assigns")
#    IO.inspect(assigns)
    ~H"""
    <form id="guess_form" phx-submit="guess">
      <div class="p-4 space-y-4">
        <div class="flex space-x-4 auto-rows-max items-center">
          <input type="text" name="guess"
            value={Phoenix.HTML.Form.normalize_value("text", @value)}
            class={[
              "block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
              "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
              "border-zinc-300 focus:border-zinc-400",
              @errors != [] && "border-rose-400 focus:border-rose-400"
            ]}
          />
          <.button>Guess</.button>
        </div>
        <label class="block text-lg font-medium text-zinc-200">
          <%= @message %>
        </label>
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
        <%= @message <> "  The word was " <> @answer <> "." %>
      </p>
      <.button phx-click="new_game">New Game</.button>
    </div>
    """
  end

  attr :puzzle, :map, required: true
  def render_guesses(assigns) do
#    IO.inspect(Puzzle.normalized_guesses(assigns.puzzle))
    ~H"""
    <div class="flex rounded-lg p-4 bg-slate-700/50">
      <div class="grid grid-flow-row auto-rows-max gap-y-4">
        <%= for guess <- Puzzle.normalized_guesses(@puzzle) do %>
          <%= render_guess guess %>
        <% end %>
        <p class="text-zinc-200"> <%= Puzzle.guesses_remaining(@puzzle) %> guesses remaining </p>
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
        <.letter_box letter={letter} hint={hint}/>
      <% end %>
    </div>
    """
#    <div class="grid grid-cols-5 gap-x-4">
  end


  attr :letter, :string, required: true
  attr :hint, :atom, default: :none

  def letter_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <div class="letterbox">
      <p class={letter_box_class(@hint)}>
        <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
      </p>
    </div>
    """
  end

  defp letter_box_class(box_type) do
    case box_type do
      :correct -> "correct"
      :wrong_letter -> "wrong_letter"
      :wrong_position -> "wrong_position"
      :none -> "none"
    end
  end

  def render_legend(assigns) do
    ~H"""
    <div class="flex rounded-lg p-4 bg-slate-700/50 grid grid-flow-row auto-rows-min gap-y-4">
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
      <.letter_box letter={@letter} hint={@hint}/>
      <p class="text-left text-xl font-medium text-zinc-200">
        <%= @description %>
      </p>
    </div>
    """
  end

  def handle_params(params, _uri, socket) do
    IO.inspect(params)
    socket =
      case params["new_game"] do
        "true" -> assign(socket, puzzle: Puzzle.new())
        _ -> socket
      end

    {:noreply, socket}
  end

  def handle_event("guess", %{"guess" => guess}, socket) do
    IO.inspect(guess)
    # lowercase
    guess = String.downcase(guess)
    with {:ok, _puzzle} <- Puzzle.verify_guess(socket.assigns.puzzle, guess),
          {:ok, puzzle} <- Puzzle.make_guess(socket.assigns.puzzle, guess)
    do
      {:noreply, assign(socket, puzzle: puzzle)}
    else
      {:error, puzzle, _reason} ->
          {:noreply, assign(socket, puzzle: puzzle)}
    end
#    case Puzzle.make_guess(socket.assigns.puzzle, guess) do
#      {:ok, %{state: :correct} = puzzle} ->
#      {:ok, puzzle} ->
#        {:noreply, assign(socket, puzzle: puzzle)}
#      {:error, puzzle, _reason} ->
#        {:noreply, assign(socket, puzzle: puzzle)}
#      end
  end

  def handle_event("new_game", _params, socket) do
#    {:noreply, push_patch(socket, to: ~p"/subtle/?new_game=true")}
#    {:noreply, push_patch(socket, to: ~p"/?new_game=true")}
    {:noreply, assign(socket, puzzle: Puzzle.new())}
  end

  def handle_event("settings", _params, socket) do
    {:noreply, assign(socket, show_settings: true)}
  end

end
