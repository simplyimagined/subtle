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
                  form: form )}
  end

  def render(assigns) do
#    <.simple_form for={@form} id="guess_form" phx-change="validate" phx-submit="guess">
#IO.puts("render.assigns")
#IO.inspect(assigns)
    ~H"""
    <h2 class="text-2xl text-zinc-200 py-6">
      <%= @message %>
    </h2>

    <div class="grid grid-flow-row gap-y-6">
      <div class="flex rounded-lg p-4 bg-slate-700/50">
        <%= if @puzzle.state == :playing do %>
          <.guess_form for={@form} message={@puzzle.message} id="guess_form" phx-submit="guess" />
        <% else %>
          <.game_over puzzle={@puzzle} />
        <% end %>
      </div>

      <%= render_guesses(assigns) %>
      <%= render_legend(assigns) %>
    </div>
    <p class="mt-40 text-zinc-200"> <%= Puzzle.summary @puzzle %> </p>
    """
#    <.input field={@form[:guess]} label="Guess" />
#    <label class="block text-lg font-medium text-zinc-200">
#      <%= @puzzle.message %>
##    </label>
#   <:actions>
#      <.button>Guess</.button>
#    </:actions>
#  </.guess_form>
end

  @doc"""
  bleh
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"
  """
  # message: "Guess a word", "You won!"
  #
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :message, :string, default: ""

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  def guess_form(assigns) do
#    IO.puts("guess_form.assigns")
#    IO.inspect(assigns)
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="p-4 space-y-4">
        <div class="flex space-x-4 auto-rows-max items-center">
          <.input field={@for[:guess]} />
          <.button>Guess</.button>
        </div>
        <label class="block text-lg font-medium text-zinc-200">
          <%= @message %>
        </label>
      </div>
    </.form>
    """
  end

  attr :puzzle, :any

  def game_over(assigns) do
    ~H"""
    <div class="flex items-center space-x-10">
      <p class="text-2xl text-zinc-200">
        <%= @puzzle.message <> "  The word was " <> @puzzle.answer <> "." %>
      </p>
      <.button phx-click="new game">New Game</.button>
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
    <div class="grid grid-cols-5 gap-x-4">
      <%= for {letter, hint} = _result <- @results do %>
        <.letter_box letter={letter} hint={hint}/>
      <% end %>
    </div>
    """
  end


  attr :letter, :string, required: true
  attr :hint, :atom, default: :none

  def letter_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <p class={[
      "w-14 h-14 justify-center items-baseline py-3 px-5",
      "text-3xl font-semibold text-zinc-200",
      if(@hint == :correct, do: "bg-green-600"),
      if(@hint == :wrong_letter, do: "bg-red-600"),
      if(@hint == :wrong_position, do: "bg-yellow-400"),
      if(@hint == :none, do: "bg-sky-500"),
      "rounded-lg border-2 border-zinc-200"
      ]}
    >
      <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
    </p>
    """
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

  def handle_event("new game", _params, socket) do
#    {:noreply, push_patch(socket, to: ~p"/subtle/?new_game=true")}
    {:noreply, push_patch(socket, to: ~p"/?new_game=true")}
  end
end
